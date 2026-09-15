const std = @import("std");
const State = @import("zetesis").state.State;

test "state preserves per-mode query and cursor" {
    var state = try State.init(std.testing.allocator, "");
    defer state.deinit();

    try state.setQuery("src");
    state.saveCursor(3);
    state.switchMode(.help, 3);
    try std.testing.expectEqualStrings("", state.currentQuery());
    try state.setQuery("split");
    state.saveCursor(1);

    state.switchMode(.files, 1);
    try std.testing.expectEqualStrings("src", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 3), state.wantedCursor());

    state.switchMode(.help, 3);
    try std.testing.expectEqualStrings("split", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 1), state.wantedCursor());
}

test "state restores file query and cursor after help search" {
    var state = try State.init(std.testing.allocator, "");
    defer state.deinit();

    try state.setQuery("picker");
    state.saveCursor(4);

    state.switchMode(.help, 4);
    try std.testing.expectEqualStrings("", state.currentQuery());
    try state.setQuery("split");
    state.saveCursor(2);

    state.switchMode(.files, 2);
    try std.testing.expectEqualStrings("picker", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 4), state.wantedCursor());

    state.switchMode(.help, 4);
    try std.testing.expectEqualStrings("split", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 2), state.wantedCursor());
}

test "state clamps cursor to visible length" {
    var state = try State.init(std.testing.allocator, "");
    defer state.deinit();

    state.saveCursor(10);
    try std.testing.expectEqual(@as(usize, 0), state.clampCursor(0));
    try std.testing.expectEqual(@as(usize, 2), state.clampCursor(3));
}
