const std = @import("std");
const flags = @import("zetesis").flags;

test "command metadata scopes flags" {
    const stdin_command = flags.findCommand("stdin").?;
    const files_command = flags.findCommand("files").?;

    try std.testing.expectEqual(flags.Flag.filter, flags.findFlag(stdin_command, "-f").?);
    try std.testing.expect(flags.findFlag(stdin_command, "--cwd") == null);
    try std.testing.expectEqual(flags.Flag.cwd, flags.findFlag(files_command, "--cwd").?);
}
