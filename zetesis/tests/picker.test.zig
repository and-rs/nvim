const std = @import("std");
const picker = @import("zetesis").picker;

test "formatSelection writes raw selected paths" {
    const output = try picker.formatSelection(std.testing.allocator, .{ .paths = &.{ "src/main.zig", "src/picker.zig" } });
    defer std.testing.allocator.free(output);
    try std.testing.expectEqualStrings("src/main.zig\nsrc/picker.zig\n", output);
}

test "session matches static index once then stays idle" {
    var session = picker.Session.init(std.testing.allocator, .{}, .fuzzy);
    defer session.deinit();
    try session.index.append("src/main.zig");
    try session.index.append("src/picker.zig");
    try session.index.append("README.md");

    try pumpIdle(&session);
    try std.testing.expectEqual(@as(usize, 3), session.ranked.len);
    try std.testing.expectEqual(@as(usize, 3), session.matched_count);
    try std.testing.expect(session.match_job == null);

    var idle_steps: usize = 0;
    while (idle_steps < 32) : (idle_steps += 1) {
        const result = try session.step(null);
        try std.testing.expect(!result.busy);
        try std.testing.expect(!result.changed);
        try std.testing.expect(!result.streaming);
        try std.testing.expectEqual(@as(usize, 3), session.matched_count);
        try std.testing.expect(session.match_job == null);
    }
}

test "session rematches once after query change" {
    var session = picker.Session.init(std.testing.allocator, .{}, .fuzzy);
    defer session.deinit();
    try session.index.append("src/main.zig");
    try session.index.append("src/picker.zig");
    try session.index.append("README.md");

    try pumpIdle(&session);
    try std.testing.expect(try session.setQuery("pick"));
    try pumpIdle(&session);
    try std.testing.expectEqual(@as(usize, 1), session.ranked.len);
    try std.testing.expectEqualStrings("src/picker.zig", session.index.items.items[session.ranked[0].source_index].path);

    const result = try session.step(null);
    try std.testing.expect(!result.busy);
    try std.testing.expect(!result.changed);
}

test "empty query ranks every item" {
    var session = picker.Session.init(std.testing.allocator, .{}, .path);
    defer session.deinit();
    try session.index.append("a.txt");
    try session.index.append("b.txt");
    try pumpIdle(&session);
    try std.testing.expectEqual(@as(usize, 2), session.ranked.len);
}

test "growing the index rematches without looping" {
    var session = picker.Session.init(std.testing.allocator, .{}, .fuzzy);
    defer session.deinit();
    try session.index.append("src/main.zig");
    try pumpIdle(&session);
    try std.testing.expectEqual(@as(usize, 1), session.ranked.len);

    try session.index.append("src/picker.zig");
    try pumpIdle(&session);
    try std.testing.expectEqual(@as(usize, 2), session.ranked.len);

    const result = try session.step(null);
    try std.testing.expect(!result.busy);
    try std.testing.expect(!result.changed);
}

test "file footer shows counts and help hint" {
    const allocator = std.testing.allocator;
    const footer = try picker.formatFooter(allocator, .files, 3, 10, false, false);
    defer allocator.free(footer);
    try std.testing.expectEqualStrings("3 / 10 files · ctrl-g help", footer);

    const marked = try picker.formatFooter(allocator, .files, 3, 10, true, true);
    defer allocator.free(marked);
    try std.testing.expectEqualStrings("3 / 10 files … · marked · ctrl-g help", marked);
}

test "help footer is static" {
    const footer = try picker.formatFooter(std.testing.allocator, .help, 2, 10, true, true);
    defer std.testing.allocator.free(footer);
    try std.testing.expectEqualStrings("esc files · enter run", footer);
}

fn pumpIdle(session: *picker.Session) !void {
    var steps: usize = 0;
    while ((try session.step(null)).busy) {
        steps += 1;
        if (steps > 10_000) return error.TestUnexpectedResult;
        try std.testing.io.sleep(.fromMilliseconds(1), .real);
    }
}
