const std = @import("std");
const key_decoder = @import("zetesis").key_decoder;

test "ctrl g opens help" {
    try std.testing.expectEqual(key_decoder.Command.help, key_decoder.decodeInput(.{ .byte = 'g', .ctrl = true }));
}

test "f1 opens help" {
    try std.testing.expectEqual(key_decoder.Command.help, key_decoder.decodeInput(.{ .special = .f1 }));
}

test "question mark is not help" {
    try std.testing.expectEqual(key_decoder.Command.none, key_decoder.decodeInput(.{ .byte = '?' }));
}
