const std = @import("std");
const vaxis = @import("vaxis");
const discover = @import("discover.zig");
const Row = @import("row.zig");
const vxfw = vaxis.vxfw;
const Index = discover.Index;
const Discover = discover.Discover;

pub const Action = enum {
    edit,
    vsplit,
    tabedit,
    quickfix,

    fn label(self: Action) []const u8 {
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
};

const Model = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    index: Index,
    discover: Discover,
    rows: std.ArrayList(Row) = .empty,
    marked: std.ArrayList(usize) = .empty,
    scroll_view: vxfw.ScrollView,
    text_field: vxfw.TextField,
    footer_arena: std.heap.ArenaAllocator,
    result: Selection = .{},
    streaming: bool = true,

    fn init(gpa: std.mem.Allocator, io: std.Io, cwd: std.process.Child.Cwd) !*Model {
        const model = try gpa.create(Model);
        errdefer gpa.destroy(model);
        model.* = .{
            .gpa = gpa,
            .io = io,
            .index = .init(gpa),
            .discover = undefined,
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
                .onSubmit = Model.onSubmit,
            },
            .footer_arena = .init(gpa),
        };
        errdefer {
            model.text_field.deinit();
            model.footer_arena.deinit();
            model.index.deinit();
            gpa.destroy(model);
        }
        try model.discover.start(gpa, io, cwd);
        return model;
    }

    fn deinit(self: *Model, gpa: std.mem.Allocator) void {
        self.discover.deinit();
        self.index.deinit();
        self.rows.deinit(gpa);
        self.marked.deinit(gpa);
        self.result.deinit(gpa);
        self.text_field.deinit();
        self.footer_arena.deinit();
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
                try ctx.tick(16, self.widget());
                return ctx.requestFocus(self.text_field.widget());
            },
            .tick => {
                if (self.streaming) {
                    try self.ingest(ctx);
                    try ctx.tick(16, self.widget());
                }
            },
            .focus_in => return ctx.requestFocus(self.text_field.widget()),
            else => {},
        }
    }

    fn ingest(self: *Model, ctx: *vxfw.EventContext) !void {
        const before = self.index.items.items.len;
        const status = try self.discover.pump(&self.index);
        try self.syncRows();
        if (self.index.items.items.len != before or status == .done) ctx.redraw = true;
        if (status == .done) self.streaming = false;
    }

    fn syncRows(self: *Model) !void {
        const items = self.index.items.items;
        if (self.rows.items.len > items.len) self.rows.clearRetainingCapacity();
        for (items, 0..) |item, i| {
            if (i < self.rows.items.len) {
                self.rows.items[i].text = item.path;
                self.rows.items[i].git_status = item.git;
                self.rows.items[i].marked = self.isMarked(i);
            } else {
                try self.rows.append(self.gpa, .{
                    .text = item.path,
                    .index = i,
                    .cursor = &self.scroll_view.cursor,
                    .marked = self.isMarked(i),
                    .git_status = item.git,
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
        const source_index: usize = cursor;
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
        if (self.scroll_view.cursor >= self.index.items.items.len) {
            ctx.quit = true;
            return ctx.consumeAndRedraw();
        }
        self.result = .{
            .action = action,
            .paths = try self.dupePaths(&.{self.scroll_view.cursor}),
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
            paths[i] = try self.gpa.dupe(u8, self.index.items.items[item_index].path);
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
            .{ self.index.items.items.len, if (self.streaming) " …" else "" },
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

    const model = try Model.init(allocator, init.io, opts.cwd);
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
        try result.writer.print(
            "{{\"action\":\"{s}\",\"kind\":\"file\",\"path\":",
            .{selection.action.label()},
        );
        try writeJsonString(&result.writer, path);
        try result.writer.writeAll("}\n");
    }
    return result.toOwnedSlice();
}

fn writeJsonString(writer: *std.Io.Writer, text: []const u8) !void {
    var json: std.json.Stringify = .{ .writer = writer };
    try json.write(text);
}

pub fn writeOutput(io: std.Io, stdout: *std.Io.Writer, data: []const u8, output_file: ?[]const u8) !void {
    if (output_file) |path| {
        try std.Io.Dir.writeFile(.cwd(), io, .{ .sub_path = path, .data = data });
        return;
    }
    try stdout.writeAll(data);
}
