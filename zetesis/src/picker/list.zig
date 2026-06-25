const std = @import("std");
const vaxis = @import("vaxis");

const matcher = @import("../match/mod.zig");
const state = @import("state.zig");
const Row = @import("row.zig");
const results = @import("results.zig");
const GitStatus = @import("../git_status.zig").GitStatus;

const vxfw = vaxis.vxfw;

pub const GitStatuses = results.GitStatuses;

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

    pub fn toggleMark(self: *State, allocator: std.mem.Allocator, mode: state.Mode, cursor: usize) !void {
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
        git_statuses: ?GitStatuses,
        query: []const u8,
        mode: state.Mode,
        cursor: *const u32,
        rank_options: matcher.RankOptions,
        show_scores: bool,
    ) !void {
        self.clear(arena);
        self.show_scores = show_scores;

        const ranked_rows = try results.rankRows(arena, source, git_statuses, query, mode, rank_options);
        try self.appendRows(arena, ranked_rows, mode, cursor, show_scores);
        try self.appendRowBoxes(arena);
    }

    fn appendRows(
        self: *State,
        arena: std.mem.Allocator,
        ranked_rows: []const results.RankedRow,
        mode: state.Mode,
        cursor: *const u32,
        show_scores: bool,
    ) !void {
        const row_styles: Row.Styles = .{};
        for (ranked_rows) |entry| {
            try self.filtered.append(arena, entry.line);
            try self.rows.append(arena, .{
                .text = entry.line.text,
                .index = self.rows.items.len,
                .cursor = cursor,
                .marked = self.isMarked(mode, entry.line.text),
                .git_status = entry.git_status,
                .score_text = if (show_scores) try scoreText(arena, entry.line.score.total()) else null,
                .match_indexes = entry.line.match_indexes,
                .styles = row_styles,
            });
        }
    }

    fn scoreText(arena: std.mem.Allocator, score: f64) ![]const u8 {
        const rounded: i64 = @intFromFloat(@round(score));
        return std.fmt.allocPrint(arena, "{d}", .{rounded});
    }

    fn appendRowBoxes(self: *State, arena: std.mem.Allocator) !void {
        for (self.rows.items) |*row| {
            try self.row_boxes.append(arena, .{
                .child = row.widget(),
                .size = .{ .width = self.available_width, .height = 1 },
            });
        }
    }

    fn isMarked(self: *const State, mode: state.Mode, text: []const u8) bool {
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

    try list.refresh(arena, &.{ "a.zig", "b.zig" }, null, "", .files, &cursor, .{}, false);
    try list.toggleMark(std.testing.allocator, .files, 0);
    try std.testing.expect(list.rows.items[0].marked);

    _ = arena_impl.reset(.free_all);
    try list.refresh(arena_impl.allocator(), &.{ "a.zig", "b.zig" }, null, "", .files, &cursor, .{}, false);
    try std.testing.expect(list.rows.items[0].marked);
}

test "help mode never marks rows" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"help row"}, null, "", .help, &cursor, .{}, false);
    try list.toggleMark(std.testing.allocator, .help, 0);
    try std.testing.expectEqual(@as(usize, 0), list.marked.items.len);
}

test "score text appears only when enabled" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"src/main.zig"}, null, "main", .files, &cursor, .{}, true);
    try std.testing.expect(list.rows.items[0].score_text != null);
}

test "score text is rounded integer" {
    const text = try State.scoreText(std.testing.allocator, 12.75);
    defer std.testing.allocator.free(text);
    try std.testing.expectEqualStrings("13", text);
}

test "list rows get git status and match indexes" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"src/main.zig"}, &.{.modified}, "main", .files, &cursor, .{}, false);
    try std.testing.expectEqual(GitStatus.modified, list.rows.items[0].git_status);
    try std.testing.expect(list.rows.items[0].match_indexes.len > 0);
}
