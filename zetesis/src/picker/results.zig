const std = @import("std");

const GitStatus = @import("../files/git.zig").GitStatus;
const matcher = @import("../match/mod.zig");
const state = @import("state.zig");

pub const GitStatuses = []const GitStatus;
pub const max_ranked_rows: usize = 512;

const git_priority_score_window: f64 = 1;

pub const RankedRow = struct {
    line: matcher.RankedLine,
    git_status: GitStatus,
};

pub fn rankRows(
    arena: std.mem.Allocator,
    source: []const []const u8,
    git_statuses: ?GitStatuses,
    query: []const u8,
    mode: state.Mode,
    rank_options: matcher.RankOptions,
) ![]const RankedRow {
    const terms = try matcher.parseQuery(arena, query);
    var options = rank_options;
    options.case_sensitive = matcher.hasUpper(query);
    if (mode == .help) options.plain = true;

    const ranked = try matcher.rankQueryTop(arena, source, terms, options, max_ranked_rows);
    return orderedRankedRows(arena, ranked, git_statuses, mode);
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

fn gitStatusPriority(status: GitStatus) u8 {
    return switch (status) {
        .modified => 0,
        .added => 1,
        .renamed => 2,
        .untracked => 3,
        .deleted => 4,
        .none => 5,
    };
}

fn gitStatusAt(statuses: ?GitStatuses, index: usize) GitStatus {
    const values = statuses orelse return .none;
    if (index >= values.len) return .none;
    return values[index];
}

test "modified rows win only when scores are close" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const rows = try rankRows(arena_impl.allocator(), &.{ "index.tsx", "src/routes/index.tsx" }, &.{ .none, .modified }, "index", .files, .{});
    try std.testing.expectEqualStrings("src/routes/index.tsx", rows[0].line.text);
    try std.testing.expectEqual(GitStatus.modified, rows[0].git_status);
}

test "clean strong matches beat weak git status matches" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const rows = try rankRows(arena_impl.allocator(), &.{ "packages/ai/pnpm-lock.yaml", ".github/workflows/ci.yml" }, &.{ .untracked, .none }, "ci", .files, .{});
    try std.testing.expectEqualStrings(".github/workflows/ci.yml", rows[0].line.text);
    try std.testing.expectEqual(GitStatus.none, rows[0].git_status);
}

test "strong filename match beats modified path match" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const rows = try rankRows(
        arena_impl.allocator(),
        &.{
            "lua/config/zetesis.lua",
            "zetesis/src/files/git.zig",
            "zetesis/src/picker/list.zig",
            "zetesis/src/git_status.zig",
            "zetesis/src/picker/results.zig",
            "lua/plugins/csvview.lua",
            "lua/plugins/scissors.lua",
        },
        &.{ .modified, .modified, .modified, .none, .none, .none, .none },
        "cs",
        .files,
        .{},
    );
    try std.testing.expectEqualStrings("lua/plugins/csvview.lua", rows[0].line.text);
    try std.testing.expectEqual(GitStatus.none, rows[0].git_status);
}

test "modified weak path match loses to stronger filename match" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const rows = try rankRows(
        arena_impl.allocator(),
        &.{
            "nvim/lua/exoskeleton.lua",
            "nvim/lua/exoskeleton/commands.lua",
            "nvim/lua/exoskeleton/pi.lua",
            "nvim/lua/exoskeleton/ui.lua",
            "nvim/lua/exoskeleton/state.lua",
        },
        &.{ .modified, .none, .none, .none, .none },
        "mu",
        .files,
        .{},
    );
    try std.testing.expectEqualStrings("nvim/lua/exoskeleton/commands.lua", rows[0].line.text);
    try std.testing.expectEqual(GitStatus.none, rows[0].git_status);
}

test "rank rows caps ranked rows" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const files = try arena_impl.allocator().alloc([]const u8, max_ranked_rows + 1);
    for (files, 0..) |*file, index| file.* = if (index == 0) "best.zig" else "other.zig";

    const rows = try rankRows(arena_impl.allocator(), files, null, "zig", .files, .{});
    try std.testing.expectEqual(max_ranked_rows, rows.len);
}
