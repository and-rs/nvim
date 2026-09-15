const std = @import("std");
const vaxis = @import("vaxis");
const discover = @import("discover.zig");
const matcher = @import("match/path.zig");
const fuzzy = @import("match/fuzzy.zig");
const Row = @import("row.zig");
const vxfw = vaxis.vxfw;
const Index = discover.Index;
const Discover = discover.Discover;

pub const Action = enum {
    edit,
    vsplit,
    tabedit,
    quickfix,

    pub fn label(self: Action) []const u8 {
        return switch (self) {
            .edit => "edit",
            .vsplit => "vsplit",
            .tabedit => "tabedit",
            .quickfix => "quickfix",
        };
    }
};

pub const Selection = struct {
    action: Action = .edit,
    paths: []const []const u8 = &.{},

    pub fn deinit(self: *Selection, allocator: std.mem.Allocator) void {
        for (self.paths) |path| allocator.free(path);
        if (self.paths.len > 0) allocator.free(self.paths);
        self.* = .{};
    }
};

pub const RunOptions = struct {
    cwd: std.process.Child.Cwd = .inherit,
    output_file: ?[]const u8 = null,
    action_file: ?[]const u8 = null,
    current_file: ?[]const u8 = null,
    plain: bool = false,
    match_mode: MatchMode = .path,
};

pub const MatchMode = enum { fuzzy, path };

pub const StaticSource = struct {
    match: []const []const u8,
    display: []const []const u8,
    output: []const []const u8,
};

pub const RankedItem = struct {
    source_index: usize,
    score: i32,
};

const MatchJob = struct {
    allocator: std.mem.Allocator,
    paths: []const []const u8,
    query: []const u8,
    options: matcher.Options,
    mode: MatchMode,
    results: []RankedItem = &.{},
    done: std.atomic.Value(bool) = .init(false),
    cancel: std.atomic.Value(bool) = .init(false),
    thread: ?std.Thread = null,

    fn start(allocator: std.mem.Allocator, paths: []const []const u8, query: []const u8, options: matcher.Options, mode: MatchMode) !*MatchJob {
        const job = try allocator.create(MatchJob);
        errdefer allocator.destroy(job);
        job.* = .{
            .allocator = allocator,
            .paths = try allocator.dupe([]const u8, paths),
            .query = try allocator.dupe(u8, query),
            .options = options,
            .mode = mode,
        };
        errdefer {
            allocator.free(job.paths);
            allocator.free(job.query);
        }
        job.thread = try std.Thread.spawn(.{}, MatchJob.run, .{job});
        return job;
    }

    fn deinit(self: *MatchJob) void {
        self.cancel.store(true, .release);
        if (self.thread) |thread| thread.join();
        if (self.results.len > 0) self.allocator.free(self.results);
        self.allocator.free(self.paths);
        self.allocator.free(self.query);
        self.allocator.destroy(self);
    }

    fn run(self: *MatchJob) void {
        defer self.done.store(true, .release);
        var ranked: std.ArrayList(RankedItem) = .empty;
        defer ranked.deinit(self.allocator);
        for (self.paths, 0..) |path, source_index| {
            if (self.cancel.load(.acquire)) return;
            const score = switch (self.mode) {
                .fuzzy => fuzzy.score(path, self.query, fuzzy.hasUpper(self.query)),
                .path => matcher.score(path, self.query, self.options),
            } orelse continue;
            ranked.append(self.allocator, .{ .source_index = source_index, .score = score }) catch return;
        }
        std.mem.sort(RankedItem, ranked.items, {}, rankedBefore);
        self.results = ranked.toOwnedSlice(self.allocator) catch return;
    }
};

fn rankedBefore(_: void, left: RankedItem, right: RankedItem) bool {
    if (left.score != right.score) return left.score > right.score;
    return left.source_index < right.source_index;
}

pub const Session = struct {
    allocator: std.mem.Allocator,
    index: Index,
    ranked: []RankedItem = &.{},
    query: []const u8 = &.{},
    match_job: ?*MatchJob = null,
    matched_count: usize = 0,
    match_options: matcher.Options,
    match_mode: MatchMode,

    pub fn init(allocator: std.mem.Allocator, match_options: matcher.Options, match_mode: MatchMode) Session {
        return .{
            .allocator = allocator,
            .index = .init(allocator),
            .match_options = match_options,
            .match_mode = match_mode,
        };
    }

    pub fn deinit(self: *Session) void {
        if (self.match_job) |job| job.deinit();
        self.match_job = null;
        self.index.deinit();
        if (self.ranked.len > 0) self.allocator.free(self.ranked);
        if (self.query.len > 0) self.allocator.free(self.query);
        self.* = undefined;
    }

    pub fn setQuery(self: *Session, query: []const u8) !bool {
        if (std.mem.eql(u8, self.query, query)) return false;
        if (self.query.len > 0) self.allocator.free(self.query);
        self.query = try self.allocator.dupe(u8, query);
        if (self.match_job) |job| job.cancel.store(true, .release);
        self.matched_count = std.math.maxInt(usize);
        return true;
    }

    pub const Step = struct {
        busy: bool,
        changed: bool,
        streaming: bool,
    };

    pub fn step(self: *Session, d: ?*Discover) !Step {
        const before = self.index.items.items.len;
        const status: discover.Pump = if (d) |disc| try disc.pump(&self.index) else .done;
        const adopted = self.adoptMatch();
        if (self.match_job == null and self.index.items.items.len != self.matched_count) {
            try self.startMatch();
        }
        return .{
            .busy = status == .more or self.match_job != null,
            .changed = adopted or self.index.items.items.len != before,
            .streaming = status == .more,
        };
    }

    fn startMatch(self: *Session) !void {
        const paths = try self.allocator.alloc([]const u8, self.index.items.items.len);
        defer self.allocator.free(paths);
        for (self.index.items.items, 0..) |item, i| paths[i] = item.path;
        self.match_job = try MatchJob.start(self.allocator, paths, self.query, self.match_options, self.match_mode);
    }

    fn adoptMatch(self: *Session) bool {
        const job = self.match_job orelse return false;
        if (!job.done.load(.acquire)) return false;
        if (job.thread) |thread| thread.join();
        job.thread = null;
        self.match_job = null;
        var adopted = false;
        if (!job.cancel.load(.acquire)) {
            if (self.ranked.len > 0) self.allocator.free(self.ranked);
            self.ranked = job.results;
            job.results = &.{};
            self.matched_count = job.paths.len;
            adopted = true;
        }
        job.deinit();
        return adopted;
    }
};

const Model = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    session: Session,
    discover: Discover = undefined,
    has_discover: bool = false,
    rows: std.ArrayList(Row) = .empty,
    marked: std.ArrayList(usize) = .empty,
    scroll_view: vxfw.ScrollView,
    text_field: vxfw.TextField,
    footer_arena: std.heap.ArenaAllocator,
    match_arena: std.heap.ArenaAllocator,
    result: Selection = .{},
    streaming: bool = true,
    display_texts: ?[]const []const u8 = null,
    output_texts: ?[]const []const u8 = null,

    fn init(gpa: std.mem.Allocator, io: std.Io, cwd: std.process.Child.Cwd, match_options: matcher.Options, match_mode: MatchMode) !*Model {
        const model = try gpa.create(Model);
        errdefer gpa.destroy(model);
        model.* = .{
            .gpa = gpa,
            .io = io,
            .session = .init(gpa, match_options, match_mode),
            .scroll_view = .{
                .draw_cursor = false,
                .cursor_indicator = .{ .char = .{ .grapheme = " ", .width = 1 } },
                .children = .{
                    .builder = .{
                        .userdata = model,
                        .buildFn = Model.widgetBuilder,
                    },
                },
            },
            .text_field = .{
                .buf = .init(gpa),
                .style = .{ .fg = .default, .bg = .default },
                .userdata = model,
                .onChange = Model.onChange,
                .onSubmit = Model.onSubmit,
            },
            .footer_arena = .init(gpa),
            .match_arena = .init(gpa),
        };
        errdefer {
            model.text_field.deinit();
            model.footer_arena.deinit();
            model.match_arena.deinit();
            model.session.deinit();
            gpa.destroy(model);
        }
        try model.discover.start(gpa, io, cwd);
        model.has_discover = true;
        return model;
    }

    fn initStatic(gpa: std.mem.Allocator, io: std.Io, source: StaticSource, match_mode: MatchMode) !*Model {
        const model = try Model.initEmpty(gpa, io, .{}, match_mode);
        errdefer model.deinit(gpa);
        model.display_texts = source.display;
        model.output_texts = source.output;
        for (source.match) |line| try model.session.index.append(line);
        return model;
    }

    fn initEmpty(gpa: std.mem.Allocator, io: std.Io, match_options: matcher.Options, match_mode: MatchMode) !*Model {
        const model = try gpa.create(Model);
        errdefer gpa.destroy(model);
        model.* = .{
            .gpa = gpa,
            .io = io,
            .session = .init(gpa, match_options, match_mode),
            .scroll_view = .{
                .draw_cursor = false,
                .cursor_indicator = .{ .char = .{ .grapheme = " ", .width = 1 } },
                .children = .{ .builder = .{ .userdata = model, .buildFn = Model.widgetBuilder } },
            },
            .text_field = .{ .buf = .init(gpa), .style = .{ .fg = .default, .bg = .default }, .userdata = model, .onChange = Model.onChange, .onSubmit = Model.onSubmit },
            .footer_arena = .init(gpa),
            .match_arena = .init(gpa),
            .streaming = false,
        };
        return model;
    }

    fn deinit(self: *Model, gpa: std.mem.Allocator) void {
        if (self.has_discover) self.discover.deinit();
        self.session.deinit();
        self.rows.deinit(gpa);
        self.marked.deinit(gpa);
        self.result.deinit(gpa);
        self.text_field.deinit();
        self.footer_arena.deinit();
        self.match_arena.deinit();
        gpa.destroy(self);
    }

    fn widget(self: *Model) vxfw.Widget {
        return .{
            .userdata = self,
            .captureHandler = Model.typeErasedCapture,
            .eventHandler = Model.typeErasedEvent,
            .drawFn = Model.typeErasedDraw,
        };
    }

    fn typeErasedCapture(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(ptr));
        switch (event) {
            .key_press => |key| {
                if (key.matches(vaxis.Key.escape, .{}) or key.matches('c', .{ .ctrl = true })) {
                    ctx.quit = true;
                    return ctx.consumeAndRedraw();
                }
                if (key.matches(vaxis.Key.enter, .{})) {
                    try self.finish(ctx, .edit);
                    return;
                }
                if (key.matches('y', .{ .ctrl = true })) {
                    try self.toggleMark(ctx);
                    return;
                }
                if (key.matches('v', .{ .ctrl = true })) {
                    try self.finish(ctx, .vsplit);
                    return;
                }
                if (key.matches('t', .{ .ctrl = true })) {
                    try self.finish(ctx, .tabedit);
                    return;
                }
                if (key.matches(vaxis.Key.down, .{}) or key.matches('j', .{}) or key.matches('n', .{ .ctrl = true })) {
                    self.scroll_view.nextItem(ctx);
                    return ctx.consumeAndRedraw();
                }
                if (key.matches(vaxis.Key.up, .{}) or key.matches('k', .{}) or key.matches('p', .{ .ctrl = true })) {
                    self.scroll_view.prevItem(ctx);
                    return ctx.consumeAndRedraw();
                }
            },
            else => {},
        }
    }

    fn typeErasedEvent(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(ptr));
        switch (event) {
            .init => {
                try self.ingest(ctx);
                return ctx.requestFocus(self.text_field.widget());
            },
            .tick => try self.ingest(ctx),
            .focus_in => return ctx.requestFocus(self.text_field.widget()),
            else => {},
        }
    }

    fn ingest(self: *Model, ctx: *vxfw.EventContext) !void {
        const result = try self.session.step(if (self.has_discover) &self.discover else null);
        if (result.changed) try self.syncRows();
        if (result.changed or result.streaming != self.streaming) ctx.redraw = true;
        self.streaming = result.streaming;
        if (result.busy) try ctx.tick(16, self.widget());
    }

    fn syncRows(self: *Model) !void {
        _ = self.match_arena.reset(.free_all);
        const items = self.session.index.items.items;
        if (self.rows.items.len > self.session.ranked.len) self.rows.clearRetainingCapacity();
        for (self.session.ranked, 0..) |ranked, i| {
            const item = items[ranked.source_index];
            const display_text = if (self.display_texts) |texts| texts[ranked.source_index] else item.path;
            const matched = if (self.session.query.len == 0) null else switch (self.session.match_mode) {
                .fuzzy => try fuzzy.match(self.match_arena.allocator(), item.path, self.session.query, fuzzy.hasUpper(self.session.query)),
                .path => try matcher.match(self.match_arena.allocator(), item.path, self.session.query, self.session.match_options),
            };
            const match_indexes = if (matched) |result| result.indexes else &.{};
            if (i < self.rows.items.len) {
                self.rows.items[i].text = display_text;
                self.rows.items[i].git_status = item.git;
                self.rows.items[i].marked = self.isMarked(ranked.source_index);
                self.rows.items[i].match_indexes = match_indexes;
            } else {
                try self.rows.append(self.gpa, .{
                    .text = display_text,
                    .index = i,
                    .cursor = &self.scroll_view.cursor,
                    .marked = self.isMarked(ranked.source_index),
                    .git_status = item.git,
                    .match_indexes = match_indexes,
                });
            }
        }
        self.scroll_view.item_count = @intCast(self.rows.items.len);
        if (self.rows.items.len == 0) {
            self.scroll_view.cursor = 0;
            return;
        }
        if (self.scroll_view.cursor >= self.rows.items.len) {
            self.scroll_view.cursor = @intCast(self.rows.items.len - 1);
        }
        self.scroll_view.ensureScroll();
    }

    fn isMarked(self: *const Model, source_index: usize) bool {
        for (self.marked.items) |marked| {
            if (marked == source_index) return true;
        }
        return false;
    }

    fn toggleMark(self: *Model, ctx: *vxfw.EventContext) !void {
        const cursor = self.scroll_view.cursor;
        if (cursor >= self.rows.items.len) return ctx.consumeAndRedraw();
        const source_index = self.session.ranked[cursor].source_index;
        if (self.markedIndex(source_index)) |found| {
            _ = self.marked.swapRemove(found);
            self.rows.items[cursor].marked = false;
        } else {
            try self.marked.append(self.gpa, source_index);
            self.rows.items[cursor].marked = true;
        }
        if (cursor + 1 < self.rows.items.len) self.scroll_view.nextItem(ctx);
        return ctx.consumeAndRedraw();
    }

    fn markedIndex(self: *const Model, source_index: usize) ?usize {
        for (self.marked.items, 0..) |marked, i| {
            if (marked == source_index) return i;
        }
        return null;
    }

    fn onSubmit(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, _: []const u8) anyerror!void {
        const ptr = maybe_ptr orelse return;
        const self: *Model = @ptrCast(@alignCast(ptr));
        try self.finish(ctx, .edit);
    }

    fn onChange(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, query: []const u8) anyerror!void {
        const ptr = maybe_ptr orelse return;
        const self: *Model = @ptrCast(@alignCast(ptr));
        if (!try self.session.setQuery(query)) return;
        try ctx.tick(16, self.widget());
        return ctx.consumeAndRedraw();
    }

    fn finish(self: *Model, ctx: *vxfw.EventContext, action: Action) !void {
        self.result.deinit(self.gpa);
        if (self.marked.items.len > 0 and action == .edit) {
            self.result = .{
                .action = .quickfix,
                .paths = try self.dupePaths(self.marked.items),
            };
            ctx.quit = true;
            return ctx.consumeAndRedraw();
        }
        if (self.scroll_view.cursor >= self.session.ranked.len) {
            ctx.quit = true;
            return ctx.consumeAndRedraw();
        }
        self.result = .{
            .action = action,
            .paths = try self.dupePaths(&.{self.session.ranked[self.scroll_view.cursor].source_index}),
        };
        ctx.quit = true;
        return ctx.consumeAndRedraw();
    }

    fn dupePaths(self: *Model, source_indexes: []const usize) ![]const []const u8 {
        const paths = try self.gpa.alloc([]const u8, source_indexes.len);
        var filled: usize = 0;
        errdefer {
            for (paths[0..filled]) |path| self.gpa.free(path);
            self.gpa.free(paths);
        }
        for (source_indexes, 0..) |item_index, i| {
            const text = if (self.output_texts) |texts| texts[item_index] else self.session.index.items.items[item_index].path;
            paths[i] = try self.gpa.dupe(u8, text);
            filled += 1;
        }
        return paths;
    }

    fn widgetBuilder(ptr: *const anyopaque, index: usize, _: usize) ?vxfw.Widget {
        const self: *const Model = @ptrCast(@alignCast(ptr));
        if (index >= self.rows.items.len) return null;
        return self.rows.items[index].widget();
    }

    fn typeErasedDraw(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(ptr));
        const max = ctx.max.size();
        const prompt: vxfw.Text = .{ .text = "$", .style = .{ .fg = .{ .index = 2 } } };
        const prompt_surface: vxfw.SubSurface = .{
            .origin = .{ .row = 0, .col = 0 },
            .surface = try prompt.draw(ctx.withConstraints(ctx.min, .{ .width = 2, .height = 1 })),
        };
        const text_field: vxfw.SubSurface = .{
            .origin = .{ .row = 0, .col = 2 },
            .surface = try self.text_field.draw(ctx.withConstraints(
                ctx.min,
                .{ .width = max.width -| 2, .height = 1 },
            )),
        };

        const list_height = if (max.height > 2) max.height - 2 else 1;
        const list_view: vxfw.SubSurface = .{
            .origin = .{ .row = 1, .col = 0 },
            .surface = try self.scroll_view.draw(ctx.withConstraints(
                ctx.min,
                .{ .width = max.width, .height = list_height },
            )),
        };

        _ = self.footer_arena.reset(.free_all);
        const footer_text = std.fmt.allocPrint(
            self.footer_arena.allocator(),
            "{d} files{s}",
            .{ self.session.index.items.items.len, if (self.streaming) " …" else "" },
        ) catch "files";
        const footer_help: vxfw.Text = .{
            .text = footer_text,
            .style = .{ .fg = .{ .index = 8 }, .bg = .{ .index = 0 } },
        };
        const footer_brand: vxfw.Text = .{
            .text = "Zetesis",
            .style = .{ .fg = .{ .index = 8 }, .bg = .{ .index = 0 } },
        };
        const spacer: vxfw.Text = .{ .text = " ", .style = .{ .bg = .{ .index = 0 } } };
        const footer_spacer: vxfw.SizedBox = .{ .size = .{ .width = 1 }, .child = spacer.widget() };
        const footer: vxfw.FlexRow = .{ .children = &.{
            .{ .widget = footer_spacer.widget(), .flex = 0 },
            .{ .widget = footer_help.widget(), .flex = 0 },
            .{ .widget = footer_spacer.widget(), .flex = 1 },
            .{ .widget = footer_brand.widget(), .flex = 0 },
            .{ .widget = footer_spacer.widget(), .flex = 0 },
        } };
        const footer_surface: vxfw.SubSurface = .{
            .origin = .{ .row = max.height -| 1, .col = 0 },
            .surface = try footer.draw(ctx.withConstraints(ctx.min, .{ .width = max.width, .height = 1 })),
        };

        const children = try ctx.arena.alloc(vxfw.SubSurface, 4);
        children[0] = prompt_surface;
        children[1] = text_field;
        children[2] = list_view;
        children[3] = footer_surface;
        return .{
            .size = max,
            .widget = self.widget(),
            .buffer = &.{},
            .children = children,
        };
    }
};

pub fn run(init: std.process.Init, allocator: std.mem.Allocator, opts: RunOptions) !Selection {
    var buffer: [1024]u8 = undefined;
    var app: vxfw.App = try .init(init.io, allocator, init.environ_map, &buffer);
    defer app.deinit();

    const model = try Model.init(allocator, init.io, opts.cwd, .{
        .current_file = opts.current_file,
        .plain = opts.plain,
    }, opts.match_mode);
    defer model.deinit(allocator);

    try app.run(model.widget(), .{});
    const result = model.result;
    model.result = .{};
    return result;
}

pub fn runStatic(init: std.process.Init, allocator: std.mem.Allocator, source: StaticSource, opts: RunOptions) !Selection {
    var buffer: [1024]u8 = undefined;
    var app: vxfw.App = try .init(init.io, allocator, init.environ_map, &buffer);
    defer app.deinit();

    const model = try Model.initStatic(allocator, init.io, source, opts.match_mode);
    defer model.deinit(allocator);

    try app.run(model.widget(), .{});
    const result = model.result;
    model.result = .{};
    return result;
}

pub fn formatSelection(allocator: std.mem.Allocator, selection: Selection) ![]u8 {
    var result: std.Io.Writer.Allocating = .init(allocator);
    errdefer result.deinit();
    for (selection.paths) |path| {
        try result.writer.writeAll(path);
        try result.writer.writeByte('\n');
    }
    return result.toOwnedSlice();
}

pub fn writeOutput(io: std.Io, stdout: *std.Io.Writer, data: []const u8, output_file: ?[]const u8) !void {
    if (output_file) |path| {
        try std.Io.Dir.writeFile(.cwd(), io, .{ .sub_path = path, .data = data });
        return;
    }
    try stdout.writeAll(data);
}

pub fn writeAction(io: std.Io, action: Action, action_file: ?[]const u8) !void {
    const path = action_file orelse return;
    var buffer: [16]u8 = undefined;
    var writer: std.Io.Writer = .fixed(&buffer);
    try writer.print("{s}\n", .{action.label()});
    try std.Io.Dir.writeFile(.cwd(), io, .{ .sub_path = path, .data = writer.buffered() });
}
