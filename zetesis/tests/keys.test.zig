const std = @import("std");
const keys = @import("zetesis").keys;

test "ctrl g and f1 open help" {
    try std.testing.expectEqual(keys.Command.help, keys.decodeInput(.{ .byte = 'g', .ctrl = true }));
    try std.testing.expectEqual(keys.Command.help, keys.decodeInput(.{ .special = .f1 }));
}

test "question mark and jk are not commands" {
    try std.testing.expectEqual(keys.Command.none, keys.decodeInput(.{ .byte = '?' }));
    try std.testing.expectEqual(keys.Command.none, keys.decodeInput(.{ .byte = 'j' }));
    try std.testing.expectEqual(keys.Command.none, keys.decodeInput(.{ .byte = 'k' }));
}

test "escape quits files but returns from help" {
    try std.testing.expectEqual(keys.Effect.quit, keys.reduce(.files, .back));
    try std.testing.expectEqual(keys.Effect.switch_files, keys.reduce(.help, .back));
}

test "help key only switches from files" {
    try std.testing.expectEqual(keys.Effect.switch_help, keys.reduce(.files, .help));
    try std.testing.expectEqual(keys.Effect.none, keys.reduce(.help, .help));
}

test "file-only actions stay out of help" {
    try std.testing.expectEqual(keys.Effect.mark, keys.reduce(.files, .mark));
    try std.testing.expectEqual(keys.Effect.none, keys.reduce(.help, .mark));
    try std.testing.expectEqual(keys.Effect.vsplit, keys.reduce(.files, .vsplit));
    try std.testing.expectEqual(keys.Effect.none, keys.reduce(.help, .vsplit));
    try std.testing.expectEqual(keys.Effect.tabedit, keys.reduce(.files, .tabedit));
    try std.testing.expectEqual(keys.Effect.none, keys.reduce(.help, .tabedit));
}

test "ctrl-c quits in both modes" {
    try std.testing.expectEqual(keys.Effect.quit, keys.reduce(.files, .quit));
    try std.testing.expectEqual(keys.Effect.quit, keys.reduce(.help, .quit));
}
