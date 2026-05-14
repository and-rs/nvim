const std = @import("std");
const vaxis = @import("vaxis");

const matcher = @import("matcher.zig");
const Row = @import("row.zig");

const vxfw = vaxis.vxfw;

const Model = struct {
    const Marked = std.ArrayList([]const u8);

    gpa: std.mem.Allocator,
    lines: []const []const u8,
    filtered: std.ArrayList(matcher.RankedLine),
    marked: Marked,
    scroll_view: vxfw.ScrollView,
    text_field: vxfw.TextField,
    arena: std.heap.ArenaAllocator,
    result: []const u8,
    rank_options: matcher.RankOptions,

    available_width: u16,
    rows: std.ArrayList(Row),
    row_boxes: std.ArrayList(vxfw.SizedBox),

    pub fn init(gpa: std.mem.Allocator, lines: []const []const u8, rank_options: matcher.RankOptions) !*Model {
        const model = try gpa.create(Model);
        errdefer gpa.destroy(model);

        model.* = .{
            .rows = .empty,
            .row_boxes = .empty,
            .available_width = 0,

            .gpa = gpa,
            .lines = lines,
            .rank_options = rank_options,
            .filtered = .empty,
            .marked = .empty,
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
        };

        return model;
    }

    pub fn deinit(self: *Model, gpa: std.mem.Allocator) void {
        self.arena.deinit();
        self.marked.deinit(gpa);
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
                try self.refresh("");
                return ctx.requestFocus(self.text_field.widget());
            },
            .key_press => |key| {
                if (key.matches('c', .{ .ctrl = true }) or key.matches('g', .{ .ctrl = true }) or key.matches(vaxis.Key.escape, .{})) {
                    ctx.quit = true;
                    return;
                }
                if (key.matches('y', .{ .ctrl = true })) {
                    try self.toggleMark();
                    if (self.scroll_view.cursor + 1 < self.filtered.items.len) {
                        self.scroll_view.nextItem(ctx);
                        return;
                    }
                    return ctx.consumeAndRedraw();
                }
                if (key.matches(vaxis.Key.down, .{}) or key.matches('j', .{}) or key.matches('n', .{ .ctrl = true })) {
                    self.scroll_view.nextItem(ctx);
                    return;
                }
                if (key.matches(vaxis.Key.up, .{}) or key.matches('k', .{}) or key.matches('p', .{ .ctrl = true })) {
                    self.scroll_view.prevItem(ctx);
                    return;
                }
                return self.scroll_view.handleEvent(ctx, event);
            },
            .focus_in => return ctx.requestFocus(self.text_field.widget()),
            else => {},
        }
    }

    fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
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
                .{ .width = max.width - 2, .height = 1 },
            )),
        };

        const list_height = if (max.height > 2) max.height - 2 else 1;

        self.available_width = max.width;

        for (self.row_boxes.items) |*box| {
            box.size.width = self.available_width;
        }

        const list_view: vxfw.SubSurface = .{
            .origin = .{ .row = 1, .col = 0 },
            .surface = try self.scroll_view.draw(ctx.withConstraints(
                ctx.min,
                .{ .width = max.width, .height = list_height },
            )),
        };

        const footer_help: vxfw.Text = .{
            .text = "enter open · ctrl-y mark · esc quit",
            .style = .{ .fg = .{ .index = 8 } },
        };
        const footer_brand: vxfw.Text = .{
            .text = "Zetesis",
            .style = .{ .fg = .{ .index = 8 } },
        };
        const spacer: vxfw.Text = .{ .text = " " };
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

    fn widgetBuilder(ptr: *const anyopaque, index: usize, _: usize) ?vxfw.Widget {
        const self: *const Model = @ptrCast(@alignCast(ptr));
        if (index >= self.row_boxes.items.len) return null;
        return self.row_boxes.items[index].widget();
    }

    fn onChange(maybe_ptr: ?*anyopaque, _: *vxfw.EventContext, query: []const u8) anyerror!void {
        const ptr = maybe_ptr orelse return;
        const self: *Model = @ptrCast(@alignCast(ptr));
        try self.refresh(query);
        self.scroll_view.cursor = 0;
    }

    fn onSubmit(maybe_ptr: ?*anyopaque, ctx: *vxfw.EventContext, _: []const u8) anyerror!void {
        const ptr = maybe_ptr orelse return;
        const self: *Model = @ptrCast(@alignCast(ptr));
        if (self.scroll_view.cursor < self.filtered.items.len) {
            self.result = self.filtered.items[self.scroll_view.cursor].text;
        }
        ctx.quit = true;
    }

    fn toggleMark(self: *Model) !void {
        if (self.scroll_view.cursor >= self.filtered.items.len) return;
        const text = self.filtered.items[self.scroll_view.cursor].text;
        if (self.markedIndex(text)) |index| {
            _ = self.marked.swapRemove(index);
            if (self.scroll_view.cursor < self.rows.items.len) {
                self.rows.items[self.scroll_view.cursor].marked = false;
            }
            return;
        }

        try self.marked.append(self.gpa, text);
        if (self.scroll_view.cursor < self.rows.items.len) {
            self.rows.items[self.scroll_view.cursor].marked = true;
        }
    }

    fn isMarked(self: *const Model, text: []const u8) bool {
        return self.markedIndex(text) != null;
    }

    fn markedIndex(self: *const Model, text: []const u8) ?usize {
        for (self.marked.items, 0..) |marked, index| {
            if (std.mem.eql(u8, marked, text)) return index;
        }
        return null;
    }

    fn refresh(self: *Model, query: []const u8) !void {
        const arena = self.arena.allocator();
        self.row_boxes.clearAndFree(arena);
        self.rows.clearAndFree(arena);
        self.filtered.clearAndFree(arena);
        _ = self.arena.reset(.free_all);

        const fresh_arena = self.arena.allocator();
        const needles = try matcher.splitQuery(fresh_arena, query);
        var rank_options = self.rank_options;
        rank_options.case_sensitive = matcher.hasUpper(query);
        const ranked = try matcher.rankAndSort(fresh_arena, self.lines, needles, rank_options);

        const row_styles: Row.Styles = .{};

        for (ranked) |line| {
            try self.filtered.append(fresh_arena, line);

            try self.rows.append(fresh_arena, .{
                .text = line.text,
                .index = self.rows.items.len,
                .cursor = &self.scroll_view.cursor,
                .marked = self.isMarked(line.text),
                .styles = row_styles,
            });
        }

        for (self.rows.items) |*row| {
            try self.row_boxes.append(fresh_arena, .{
                .child = row.widget(),
                .size = .{ .width = self.available_width, .height = 1 },
            });
        }
    }
};

pub fn run(init: std.process.Init, allocator: std.mem.Allocator, lines: []const []const u8, rank_options: matcher.RankOptions) ![]const u8 {
    var buffer: [1024]u8 = undefined;
    var app: vxfw.App = try .init(init.io, allocator, init.environ_map, &buffer);
    defer app.deinit();

    const model = try Model.init(allocator, lines, rank_options);
    defer model.deinit(allocator);

    try app.run(model.widget(), .{});
    return model.result;
}
