const std = @import("std");
const vaxis = @import("vaxis");

const actions = @import("actions.zig");
const key_decoder = @import("key_decoder.zig");
const matcher = @import("../match/mod.zig");
const reducer = @import("reducer.zig");
const state = @import("state.zig");
const list = @import("list.zig");
const protocol = @import("protocol.zig");

const Action = actions.Action;
const Mode = state.Mode;
const vxfw = vaxis.vxfw;

const Model = struct {
    gpa: std.mem.Allocator,
    lines: []const []const u8,
    git_statuses: ?list.GitStatuses,
    list: list.State,
    scroll_view: vxfw.ScrollView,
    text_field: vxfw.TextField,
    arena: std.heap.ArenaAllocator,
    result: []const u8,
    rank_options: matcher.RankOptions,
    show_scores: bool,
    state: state.State,
    pub fn init(gpa: std.mem.Allocator, lines: []const []const u8, git_statuses: ?list.GitStatuses, rank_options: matcher.RankOptions, show_scores: bool) !*Model {
        const model = try gpa.create(Model);
        errdefer gpa.destroy(model);

        model.* = .{
            .list = .{},
            .gpa = gpa,
            .lines = lines,
            .git_statuses = git_statuses,
            .rank_options = rank_options,
            .show_scores = show_scores,
            .scroll_view = .{
                .draw_cursor = false,
                .cursor_indicator = .{
                    .char = .{ .grapheme = " ", .width = 1 },
                },
                .children = .{
                    .builder = .{
                        .userdata = model,
                        .buildFn = Model.widgetBuilder,
                    },
                },
            },
            .text_field = .{
                .buf = .init(gpa),
                .userdata = model,
                .onChange = Model.onChange,
                .onSubmit = Model.onSubmit,
            },
            .arena = .init(gpa),
            .result = "",
            .state = state.State.init(gpa),
        };

        return model;
    }

    pub fn deinit(self: *Model, gpa: std.mem.Allocator) void {
        self.state.deinit();
        self.arena.deinit();
        self.list.deinit(gpa);
        self.text_field.deinit();
        gpa.destroy(self);
    }

    pub fn widget(self: *Model) vxfw.Widget {
        return .{
            .userdata = self,
            .eventHandler = Model.typeErasedEventHandler,
            .drawFn = Model.typeErasedDrawFn,
        };
    }

    fn typeErasedEventHandler(ptr: *anyopaque, ctx: *vxfw.EventContext, event: vxfw.Event) anyerror!void {
        const self: *Model = @ptrCast(@alignCast(ptr));
        switch (event) {
            .init => {
                try self.refresh(self.state.currentQuery(), .reset);
                return ctx.requestFocus(self.text_field.widget());
            },
            .key_press => |key| {
                const command = key_decoder.decodeKey(key);
                const effect = reducer.reduce(self.state.mode, command);
                return self.applyEffect(ctx, event, effect);
            },
            .focus_in => return ctx.requestFocus(self.text_field.widget()),
            else => {},
        }
    }

    fn applyEffect(self: *Model, ctx: *vxfw.EventContext, event: vxfw.Event, effect: reducer.Effect) !void {
        switch (effect) {
            .none => return self.scroll_view.handleEvent(ctx, event),
            .quit => {
                ctx.quit = true;
                return;
            },
            .switch_files => return self.switchMode(ctx, .files),
            .switch_help => return self.switchMode(ctx, .help),
            .open => return self.open(ctx),
            .mark => return self.markCurrent(ctx),
            .vsplit => return self.finishAction(ctx, .vsplit),
            .tabedit => return self.finishAction(ctx, .tabedit),
            .move_down => return self.moveCursor(ctx, .down),
            .move_up => return self.moveCursor(ctx, .up),
        }
    }

    fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
        const self: *Model = @ptrCast(@alignCast(ptr));
        const max = ctx.max.size();
        self.syncViewport(.preserve);

        const prompt_text = if (self.state.mode == .help) ":" else "$";
        const prompt: vxfw.Text = .{ .text = prompt_text, .style = .{ .fg = .{ .index = 2 } } };
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

        self.list.setWidth(max.width);

        const list_view: vxfw.SubSurface = .{
            .origin = .{ .row = 1, .col = 0 },
            .surface = try self.scroll_view.draw(ctx.withConstraints(
                ctx.min,
                .{ .width = max.width, .height = list_height },
            )),
        };

        const footer_help: vxfw.Text = .{
            .text = self.footerText(),
            .style = .{ .fg = .{ .index = 8 }, .bg = .{ .index = 0 } },
        };
        const footer_brand: vxfw.Text = .{
            .text = "Zetesis",
            .style = .{ .fg = .{ .index = 8 }, .bg = .{ .index = 0 } },
        };
        const spacer: vxfw.Text = .{
            .text = " ",
            .style = .{ .bg = .{ .index = 0 } },
        };
        const footer_spacer: vxfw.SizedBox = .{
            .size = .{ .width = 1 },
            .child = spacer.widget(),
        };
        const footer: vxfw.FlexRow = .{ .children = &.{
            .{ .widget = footer_spacer.widget(), .flex = 0 },
            .{ .widget = footer_help.widget(), .flex = 0 },
            .{ .widget = footer_spacer.widget(), .flex = 1 },
            .{ .widget = footer_brand.widget(), .flex = 0 },
            .{ .widget = footer_spacer.widget(), .flex = 0 },
        } };

        const footer_surface: vxfw.SubSurface = .{
            .origin = .{ .row = max.height - 1, .col = 0 },
            .surface = try footer.draw(ctx.withConstraints(
                ctx.min,
                .{ .width = max.width, .height = 1 },
            )),
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

    fn footerText(self: *const Model) []const u8 {
        return switch (self.state.mode) {
            .files => if (self.show_scores) "ctrl-; help · scores on" else "ctrl-; help",
            .help => if (self.show_scores) "esc files · enter run · scores on" else "esc files · enter run",
        };
    }

    fn widgetBuilder(ptr: *const anyopaque, index: usize, _: usize) ?vxfw.Widget {
        const self: *const Model = @ptrCast(@alignCast(ptr));
        return self.list.widgetAt(index);
    }

    fn onChange(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, query: []const u8) anyerror!void {
        const ptr = maybe_ptr orelse return;
        const self: *Model = @ptrCast(@alignCast(ptr));
        try self.state.setQuery(query);
        try self.refresh(query, .reset);
        self.state.saveCursor(self.scroll_view.cursor);
        return ctx.consumeAndRedraw();
    }

    fn onSubmit(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, _: []const u8) anyerror!void {
        const ptr = maybe_ptr orelse return;
        const self: *Model = @ptrCast(@alignCast(ptr));
        return self.open(ctx);
    }

    fn open(self: *Model, ctx: *vxfw.EventContext) !void {
        return switch (self.state.mode) {
            .files => self.finishAction(ctx, .edit),
            .help => self.executeHelpAction(ctx),
        };
    }

    fn executeHelpAction(self: *Model, ctx: *vxfw.EventContext) !void {
        const entry = self.currentHelpEntry() orelse return ctx.consumeAndRedraw();
        return self.applyHelpDispatch(ctx, actions.dispatchForHelpAction(entry.action));
    }

    fn applyHelpDispatch(self: *Model, ctx: *vxfw.EventContext, dispatch: actions.HelpDispatch) !void {
        switch (dispatch) {
            .back => return self.switchMode(ctx, .files),
            .quit => {
                ctx.quit = true;
                return;
            },
            .mark => {
                try self.switchMode(ctx, .files);
                return self.markCurrent(ctx);
            },
            .file_action => |action| {
                try self.switchMode(ctx, .files);
                return self.finishAction(ctx, action);
            },
        }
    }

    fn currentHelpEntry(self: *const Model) ?actions.HelpEntry {
        if (self.state.mode != .help) return null;
        const text = self.list.currentText(self.scroll_view.cursor) orelse return null;
        return actions.helpEntryForText(text);
    }

    fn switchMode(self: *Model, ctx: *vxfw.EventContext, mode: Mode) !void {
        self.state.switchMode(mode, self.scroll_view.cursor);
        try self.setTextFieldValue(self.state.currentQuery());
        try self.refresh(self.state.currentQuery(), .reset);
        self.scroll_view.cursor = @intCast(self.state.clampCursor(self.list.len()));
        self.syncViewport(.preserve);
        return ctx.consumeAndRedraw();
    }

    const ViewportSync = enum { preserve, reset };

    const CursorDirection = enum { down, up };

    fn moveCursor(self: *Model, ctx: *vxfw.EventContext, direction: CursorDirection) void {
        self.syncViewport(.preserve);
        switch (direction) {
            .down => self.scroll_view.nextItem(ctx),
            .up => self.scroll_view.prevItem(ctx),
        }
        self.syncViewport(.preserve);
        self.state.saveCursor(self.scroll_view.cursor);
    }

    fn syncViewport(self: *Model, mode: ViewportSync) void {
        const count = self.list.len();
        self.scroll_view.item_count = @intCast(count);

        if (mode == .reset) self.scroll_view.scroll = .{};
        if (count == 0) {
            self.scroll_view.cursor = 0;
            self.scroll_view.scroll = .{};
            return;
        }

        if (self.scroll_view.cursor >= count) self.scroll_view.cursor = @intCast(count - 1);
        if (self.scroll_view.scroll.top >= count) self.scroll_view.scroll = .{};
        self.scroll_view.ensureScroll();
    }

    fn setTextFieldValue(self: *Model, query: []const u8) !void {
        self.text_field.buf.clearAndFree();
        try self.text_field.buf.insertSliceAtCursor(query);
        self.text_field.buf.moveGapLeft(0);
        self.text_field.buf.allocator.free(self.text_field.previous_val);
        self.text_field.previous_val = if (query.len == 0) "" else try self.text_field.buf.allocator.dupe(u8, query);
    }

    fn markCurrent(self: *Model, ctx: *vxfw.EventContext) !void {
        try self.list.toggleMark(self.gpa, self.state.mode, self.scroll_view.cursor);
        if (self.scroll_view.cursor + 1 < self.list.len()) {
            self.scroll_view.nextItem(ctx);
            self.syncViewport(.preserve);
            self.state.saveCursor(self.scroll_view.cursor);
            return;
        }
        self.state.saveCursor(self.scroll_view.cursor);
        return ctx.consumeAndRedraw();
    }

    fn finishAction(self: *Model, ctx: *vxfw.EventContext, action: Action) !void {
        if (self.list.marked.items.len > 0 and action == .edit) {
            self.result = try protocol.formatActionResult(self.gpa, .quickfix, self.list.marked.items);
            ctx.quit = true;
            return;
        }

        self.syncViewport(.preserve);
        const path = self.list.currentText(self.scroll_view.cursor) orelse return ctx.consumeAndRedraw();
        self.result = try protocol.formatActionResult(self.gpa, action, &.{path});
        ctx.quit = true;
    }

    fn refresh(self: *Model, query: []const u8, viewport_sync: ViewportSync) !void {
        const arena = self.arena.allocator();
        self.list.clear(arena);
        _ = self.arena.reset(.free_all);

        const fresh_arena = self.arena.allocator();
        const source = switch (self.state.mode) {
            .files => self.lines,
            .help => actions.help_lines[0..],
        };
        const git_statuses = switch (self.state.mode) {
            .files => self.git_statuses,
            .help => null,
        };
        try self.list.refresh(
            fresh_arena,
            source,
            git_statuses,
            query,
            self.state.mode,
            &self.scroll_view.cursor,
            self.rank_options,
            self.show_scores,
        );
        self.syncViewport(viewport_sync);
    }
};

pub fn run(init: std.process.Init, allocator: std.mem.Allocator, lines: []const []const u8, git_statuses: ?list.GitStatuses, rank_options: matcher.RankOptions, show_scores: bool) ![]const u8 {
    var buffer: [1024]u8 = undefined;
    var app: vxfw.App = try .init(init.io, allocator, init.environ_map, &buffer);
    defer app.deinit();

    const model = try Model.init(allocator, lines, git_statuses, rank_options, show_scores);
    defer model.deinit(allocator);

    try app.run(model.widget(), .{});
    return model.result;
}
