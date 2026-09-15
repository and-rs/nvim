const std = @import("std");
const zetesis = @import("zetesis");
const GitStatus = zetesis.git.GitStatus;
const results = zetesis.results;

test "modified rows win only when scores are close" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const rows = try results.rankRows(arena_impl.allocator(), &.{ "index.tsx", "src/routes/index.tsx" }, &.{ .none, .modified }, "index", .files, .{});
    try std.testing.expectEqualStrings("src/routes/index.tsx", rows[0].line.text);
    try std.testing.expectEqual(GitStatus.modified, rows[0].git_status);
}

test "clean strong matches beat weak git status matches" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const rows = try results.rankRows(arena_impl.allocator(), &.{ "packages/ai/pnpm-lock.yaml", ".github/workflows/ci.yml" }, &.{ .untracked, .none }, "ci", .files, .{});
    try std.testing.expectEqualStrings(".github/workflows/ci.yml", rows[0].line.text);
    try std.testing.expectEqual(GitStatus.none, rows[0].git_status);
}

test "strong filename match beats modified path match" {
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    const rows = try results.rankRows(
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

    const rows = try results.rankRows(
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

    const files = try arena_impl.allocator().alloc([]const u8, results.max_ranked_rows + 1);
    for (files, 0..) |*file, index| file.* = if (index == 0) "best.zig" else "other.zig";

    const rows = try results.rankRows(arena_impl.allocator(), files, null, "zig", .files, .{});
    try std.testing.expectEqual(results.max_ranked_rows, rows.len);
}
