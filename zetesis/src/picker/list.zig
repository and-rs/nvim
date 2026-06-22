const std = @import("std");
const vaxis = @import("vaxis");

const matcher = @import("../match/mod.zig");
const state = @import("state.zig");
const Row = @import("row.zig");

const vxfw = vaxis.vxfw;

pub const GitStatuses = []const Row.GitStatus;
const max_ranked_rows: usize = 512;
const git_priority_score_window: f64 = 25;

pub const State = struct {
    const Marked = std.ArrayList([]const u8);
    const RankedRow = struct {
        line: matcher.RankedLine,
        git_status: Row.GitStatus,
    };

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

        const needles = try matcher.splitQuery(arena, query);
        var options = rank_options;
        options.case_sensitive = matcher.hasUpper(query);
        if (mode == .help) options.plain = true;
        const ranked = try matcher.rankAndSortLimit(arena, source, needles, options, max_ranked_rows);

        const ranked_rows = try orderedRankedRows(arena, ranked, git_statuses, mode);
        try self.appendRows(arena, ranked_rows, mode, cursor, show_scores);
        try self.appendRowBoxes(arena);
    }

    fn orderedRankedRows(
        arena: std.mem.Allocator,
        ranked: []const matcher.RankedLine,
        git_statuses: ?GitStatuses,
        mode: state.Mode,
    ) ![]const RankedRow {
        const statuses = if (mode == .files) git_statuses else null;
        var rows: std.ArrayList(RankedRow) = .empty;
        for (ranked) |line| {
            try rows.append(arena, .{
                .line = line,
                .git_status = gitStatusAt(statuses, line.source_index),
            });
        }

        if (mode == .files) std.mem.sort(RankedRow, rows.items, {}, rankedRowLessThan);
        return rows.toOwnedSlice(arena);
    }

    fn appendRows(
        self: *State,
        arena: std.mem.Allocator,
        ranked_rows: []const RankedRow,
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

    fn rankedRowLessThan(_: void, left: RankedRow, right: RankedRow) bool {
        const left_score = left.line.score.total();
        const right_score = right.line.score.total();
        const score_gap = @abs(left_score - right_score);

        if (score_gap <= git_priority_score_window) {
            const left_priority = gitStatusPriority(left.git_status);
            const right_priority = gitStatusPriority(right.git_status);
            if (left_priority != right_priority) return left_priority < right_priority;
        }

        return left_score > right_score;
    }

    fn gitStatusPriority(status: Row.GitStatus) u8 {
        return switch (status) {
            .modified => 0,
            .added => 1,
            .renamed => 2,
            .untracked => 3,
            .deleted => 4,
            .none => 5,
        };
    }

    fn gitStatusAt(statuses: ?GitStatuses, index: usize) Row.GitStatus {
        const values = statuses orelse return .none;
        if (index >= values.len) return .none;
        return values[index];
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
    try std.testing.expectEqual(Row.GitStatus.modified, list.rows.items[0].git_status);
    try std.testing.expect(list.rows.items[0].match_indexes.len > 0);
}

test "modified rows win only when scores are close" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{ "index.tsx", "src/routes/index.tsx" }, &.{ .none, .modified }, "index", .files, &cursor, .{}, true);
    try std.testing.expectEqualStrings("src/routes/index.tsx", list.currentText(0).?);
    try std.testing.expectEqual(Row.GitStatus.modified, list.rows.items[0].git_status);
    try std.testing.expectEqual(@as(usize, 0), list.rows.items[0].index);
}

test "clean strong matches beat weak git status matches" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try list.refresh(arena_impl.allocator(), &.{ "packages/ai/pnpm-lock.yaml", ".github/workflows/ci.yml" }, &.{ .untracked, .none }, "ci", .files, &cursor, .{}, true);
    try std.testing.expectEqualStrings(".github/workflows/ci.yml", list.currentText(0).?);
    try std.testing.expectEqual(Row.GitStatus.none, list.rows.items[0].git_status);
}

test "list refresh caps ranked rows" {
    var list: State = .{};
    defer list.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const files = try arena_impl.allocator().alloc([]const u8, max_ranked_rows + 1);
    for (files, 0..) |*file, index| file.* = if (index == 0) "best.zig" else "other.zig";

    try list.refresh(arena_impl.allocator(), files, null, "zig", .files, &cursor, .{}, false);
    try std.testing.expectEqual(max_ranked_rows, list.len());
}
