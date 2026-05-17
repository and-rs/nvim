const std = @import("std");
const vaxis = @import("vaxis");

const matcher = @import("matcher.zig");
const picker_state = @import("picker_state.zig");
const Row = @import("row.zig");

const vxfw = vaxis.vxfw;

pub const State = struct {
    const Marked = std.ArrayList([]const u8);

    filtered: std.ArrayList(matcher.RankedLine) = .empty,
    marked: Marked = .empty,
    rows: std.ArrayList(Row) = .empty,
    row_boxes: std.ArrayList(vxfw.SizedBox) = .empty,
    available_width: u16 = 0,
    show_scores: bool = false,

    pub fn deinit(self: *State, allocator: std.mem.Allocator) void {
        self.marked.deinit(allocator);
        self.* = .{};
    }

    pub fn clear(self: *State, allocator: std.mem.Allocator) void {
        self.row_boxes.clearAndFree(allocator);
        self.rows.clearAndFree(allocator);
        self.filtered.clearAndFree(allocator);
    }
    pub fn len(self: *const State) usize {
        return self.filtered.items.len;
    }

    pub fn widgetAt(self: *const State, index: usize) ?vxfw.Widget {
        if (index >= self.row_boxes.items.len) return null;
        return self.row_boxes.items[index].widget();
    }

    pub fn setWidth(self: *State, width: u16) void {
        self.available_width = width;
        for (self.row_boxes.items) |*box| {
            box.size.width = width;
        }
    }

    pub fn currentText(self: *const State, cursor: usize) ?[]const u8 {
        if (cursor >= self.filtered.items.len) return null;
        return self.filtered.items[cursor].text;
    }

    pub fn toggleMark(self: *State, allocator: std.mem.Allocator, mode: picker_state.Mode, cursor: usize) !void {
        if (mode != .files) return;
        const text = self.currentText(cursor) orelse return;
        if (self.markedIndex(text)) |index| {
            _ = self.marked.swapRemove(index);
            if (cursor < self.rows.items.len) self.rows.items[cursor].marked = false;
            return;
        }

        try self.marked.append(allocator, text);
        if (cursor < self.rows.items.len) self.rows.items[cursor].marked = true;
    }

    pub fn refresh(
        self: *State,
        arena: std.mem.Allocator,
        source: []const []const u8,
        query: []const u8,
        mode: picker_state.Mode,
        cursor: *const u32,
        rank_options: matcher.RankOptions,
        show_scores: bool,
    ) !void {
        self.clear(arena);
        self.show_scores = show_scores;

        const needles = try matcher.splitQuery(arena, query);
        var options = rank_options;
        options.case_sensitive = matcher.hasUpper(query);
        if (mode == .help) options.plain = true;
        const ranked = try matcher.rankAndSort(arena, source, needles, options);

        const row_styles: Row.Styles = .{};
        for (ranked) |line| {
            try self.filtered.append(arena, line);
            try self.rows.append(arena, .{
                .text = line.text,
                .index = self.rows.items.len,
                .cursor = cursor,
                .marked = self.isMarked(mode, line.text),
                .score_text = if (show_scores) try std.fmt.allocPrint(arena, "{d:.2}", .{line.score.total()}) else null,
                .styles = row_styles,
            });
        }

        for (self.rows.items) |*row| {
            try self.row_boxes.append(arena, .{
                .child = row.widget(),
                .size = .{ .width = self.available_width, .height = 1 },
            });
        }
    }

    fn isMarked(self: *const State, mode: picker_state.Mode, text: []const u8) bool {
        if (mode != .files) return false;
        return self.markedIndex(text) != null;
    }

    fn markedIndex(self: *const State, text: []const u8) ?usize {
        for (self.marked.items, 0..) |marked, index| {
            if (std.mem.eql(u8, marked, text)) return index;
        }
        return null;
    }
};

test "list state restores marks after refresh" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();
    const arena = arena_impl.allocator();

    try list.refresh(arena, &.{ "a.zig", "b.zig" }, "", .files, &cursor, .{}, false);
    try list.toggleMark(std.testing.allocator, .files, 0);
    try std.testing.expect(list.rows.items[0].marked);

    _ = arena_impl.reset(.free_all);
    try list.refresh(arena_impl.allocator(), &.{ "a.zig", "b.zig" }, "", .files, &cursor, .{}, false);
    try std.testing.expect(list.rows.items[0].marked);
}

test "help mode never marks rows" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"help row"}, "", .help, &cursor, .{}, false);
    try list.toggleMark(std.testing.allocator, .help, 0);
    try std.testing.expectEqual(@as(usize, 0), list.marked.items.len);
}

test "score text appears only when enabled" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"src/main.zig"}, "main", .files, &cursor, .{}, true);
    try std.testing.expect(list.rows.items[0].score_text != null);
}