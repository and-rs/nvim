const std = @import("std");
const flags = @import("zetesis").flags;

test "command metadata scopes flags" {
    const stdin_command = flags.findCommand("stdin").?;
    const files_command = flags.findCommand("files").?;

    try std.testing.expectEqual(flags.Flag.filter, flags.findFlag(stdin_command, "-f").?);
    try std.testing.expectEqual(flags.Flag.nth, flags.findFlag(stdin_command, "--nth").?);
    try std.testing.expectEqual(flags.Flag.with_nth, flags.findFlag(stdin_command, "--with-nth").?);
    try std.testing.expectEqual(flags.Flag.accept_nth, flags.findFlag(stdin_command, "--accept-nth").?);
    try std.testing.expectEqual(flags.Flag.ansi, flags.findFlag(stdin_command, "--ansi").?);
    try std.testing.expectEqual(flags.Flag.matcher, flags.findFlag(stdin_command, "--matcher").?);
    try std.testing.expectEqual(flags.Flag.action_file, flags.findFlag(stdin_command, "--action-file").?);
    try std.testing.expect(flags.findFlag(stdin_command, "--cwd") == null);
    try std.testing.expectEqual(flags.Flag.cwd, flags.findFlag(files_command, "--cwd").?);
    try std.testing.expect(flags.findFlag(files_command, "--nth") == null);
}
