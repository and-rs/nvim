const std = @import("std");
const zetesis = @import("zetesis");
const GitStatus = zetesis.git.GitStatus;
const list = zetesis.list;

test "list state restores marks after refresh" {
    var state: list.State = .{};
    defer state.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();
    const arena = arena_impl.allocator();

    try state.refresh(arena, &.{ "a.zig", "b.zig" }, null, null, "", .files, &cursor, .{}, false, false);
    try state.toggleMark(std.testing.allocator, .files, 0);
    try std.testing.expect(state.rows.items[0].marked);

    state.clear(arena);
    _ = arena_impl.reset(.free_all);
    try state.refresh(arena_impl.allocator(), &.{ "a.zig", "b.zig" }, null, null, "", .files, &cursor, .{}, false, false);
    try std.testing.expect(state.rows.items[0].marked);
}

test "help mode never marks rows" {
    var state: list.State = .{};
    defer state.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try state.refresh(arena_impl.allocator(), &.{"help row"}, null, null, "", .help, &cursor, .{}, false, false);
    try state.toggleMark(std.testing.allocator, .help, 0);
    try std.testing.expectEqual(@as(usize, 0), state.marked.items.len);
}

test "score text appears only when enabled" {
    var state: list.State = .{};
    defer state.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try state.refresh(arena_impl.allocator(), &.{"src/main.zig"}, null, null, "main", .files, &cursor, .{}, true, false);
    try std.testing.expect(state.rows.items[0].score_text != null);
}

test "score text is rounded integer" {
    const text = try list.State.scoreText(std.testing.allocator, 12.75) orelse return error.TestUnexpectedResult;
    defer std.testing.allocator.free(text);
    try std.testing.expectEqualStrings("13", text);
}

test "score text is hidden at zero" {
    try std.testing.expectEqual(@as(?[]const u8, null), try list.State.scoreText(std.testing.allocator, 0));
    try std.testing.expectEqual(@as(?[]const u8, null), try list.State.scoreText(std.testing.allocator, 0.4));
}

test "list rows get git status and match indexes" {
    var state: list.State = .{};
    defer state.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try state.refresh(arena_impl.allocator(), &.{"src/main.zig"}, null, &.{.modified}, "main", .files, &cursor, .{}, false, false);
    try std.testing.expectEqual(GitStatus.modified, state.rows.items[0].git_status);
    try std.testing.expect(state.rows.items[0].match_indexes.len > 0);
}

test "list can render display text separate from match text" {
    var state: list.State = .{};
    defer state.deinit(std.testing.allocator);

    var cursor: u32 = 0;
    var arena_impl = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_impl.deinit();

    try state.refresh(arena_impl.allocator(), &.{"match-value"}, &.{"shown-value"}, null, "match", .files, &cursor, .{}, false, false);
    try std.testing.expectEqualStrings("shown-value", state.currentDisplayText(0).?);
    try std.testing.expectEqual(@as(usize, 0), state.currentSourceIndex(0).?);
}
