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
    const Marked = std.ArrayList(usize);

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

    pub fn currentDisplayText(self: *const State, cursor: usize) ?[]const u8 {
        if (cursor >= self.rows.items.len) return null;
        return self.rows.items[cursor].text;
    }

    pub fn currentSourceIndex(self: *const State, cursor: usize) ?usize {
        if (cursor >= self.filtered.items.len) return null;
        return self.filtered.items[cursor].source_index;
    }

    pub fn toggleMark(self: *State, allocator: std.mem.Allocator, mode: state.Mode, cursor: usize) !void {
        if (mode != .files) return;
        const source_index = self.currentSourceIndex(cursor) orelse return;
        if (self.markedIndex(source_index)) |index| {
            _ = self.marked.swapRemove(index);
            if (cursor < self.rows.items.len) self.rows.items[cursor].marked = false;
            return;
        }

        try self.marked.append(allocator, source_index);
        if (cursor < self.rows.items.len) self.rows.items[cursor].marked = true;
    }

    pub fn refresh(
        self: *State,
        arena: std.mem.Allocator,
        source: []const []const u8,
        display_texts: ?[]const []const u8,
        git_statuses: ?GitStatuses,
        query: []const u8,
        mode: state.Mode,
        cursor: *const u32,
        rank_options: matcher.RankOptions,
        show_scores: bool,
        ordered: bool,
    ) !void {
        self.clear(arena);
        self.show_scores = show_scores;

        if (ordered) {
            try self.appendOrderedRows(arena, source, display_texts, mode, cursor);
        } else {
            const ranked_rows = try results.rankRows(arena, source, git_statuses, query, mode, rank_options);
            try self.appendRows(arena, ranked_rows, display_texts, mode, cursor, show_scores);
        }
        try self.appendRowBoxes(arena);
    }

    fn appendOrderedRows(
        self: *State,
        arena: std.mem.Allocator,
        source: []const []const u8,
        display_texts: ?[]const []const u8,
        mode: state.Mode,
        cursor: *const u32,
    ) !void {
        const row_styles: Row.Styles = .{};
        for (source, 0..) |text, source_index| {
            try self.filtered.append(arena, .{
                .text = text,
                .source_index = source_index,
                .score = .{},
                .match_indexes = &.{},
            });
            try self.rows.append(arena, .{
                .text = displayTextAt(display_texts, source_index, text),
                .index = self.rows.items.len,
                .cursor = cursor,
                .marked = self.isMarked(mode, source_index),
                .git_status = .none,
                .score_text = null,
                .match_indexes = &.{},
                .styles = row_styles,
            });
        }
    }

    fn appendRows(
        self: *State,
        arena: std.mem.Allocator,
        ranked_rows: []const results.RankedRow,
        display_texts: ?[]const []const u8,
        mode: state.Mode,
        cursor: *const u32,
        show_scores: bool,
    ) !void {
        const row_styles: Row.Styles = .{};
        for (ranked_rows) |entry| {
            try self.filtered.append(arena, entry.line);
            try self.rows.append(arena, .{
                .text = displayTextAt(display_texts, entry.line.source_index, entry.line.text),
                .index = self.rows.items.len,
                .cursor = cursor,
                .marked = self.isMarked(mode, entry.line.source_index),
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

    fn isMarked(self: *const State, mode: state.Mode, source_index: usize) bool {
        if (mode != .files) return false;
        return self.markedIndex(source_index) != null;
    }

    fn markedIndex(self: *const State, source_index: usize) ?usize {
        for (self.marked.items, 0..) |marked, index| {
            if (marked == source_index) return index;
        }
        return null;
    }

    fn displayTextAt(display_texts: ?[]const []const u8, source_index: usize, fallback: []const u8) []const u8 {
        const texts = display_texts orelse return fallback;
        if (source_index >= texts.len) return fallback;
        return texts[source_index];
    }
};

test "list state restores marks after refresh" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();
    const arena = arena_impl.allocator();

    try list.refresh(arena, &.{ "a.zig", "b.zig" }, null, null, "", .files, &cursor, .{}, false, false);
    try list.toggleMark(std.testing.allocator, .files, 0);
    try std.testing.expect(list.rows.items[0].marked);

    _ = arena_impl.reset(.free_all);
    try list.refresh(arena_impl.allocator(), &.{ "a.zig", "b.zig" }, null, null, "", .files, &cursor, .{}, false, false);
    try std.testing.expect(list.rows.items[0].marked);
}

test "help mode never marks rows" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"help row"}, null, null, "", .help, &cursor, .{}, false, false);
    try list.toggleMark(std.testing.allocator, .help, 0);
    try std.testing.expectEqual(@as(usize, 0), list.marked.items.len);
}

test "score text appears only when enabled" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"src/main.zig"}, null, null, "main", .files, &cursor, .{}, true, false);
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

    try list.refresh(arena_impl.allocator(), &.{"src/main.zig"}, null, &.{.modified}, "main", .files, &cursor, .{}, false, false);
    try std.testing.expectEqual(GitStatus.modified, list.rows.items[0].git_status);
    try std.testing.expect(list.rows.items[0].match_indexes.len > 0);
}

test "list can render display text separate from match text" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{"match-value"}, &.{"shown-value"}, null, "match", .files, &cursor, .{}, false, false);
    try std.testing.expectEqualStrings("shown-value", list.currentDisplayText(0).?);
    try std.testing.expectEqual(@as(usize, 0), list.currentSourceIndex(0).?);
}
