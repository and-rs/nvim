const std = @import("std");
const git = @import("git.zig");
const walk = @import("walk.zig");

pub const Entry = git.Entry;

pub fn collectProjectEntries(allocator: std.mem.Allocator, io: std.Io, cwd: []const u8) ![]const Entry {
    var dir = try std.Io.Dir.openDir(.cwd(), io, cwd, .{ .iterate = true });
    defer dir.close(io);

    const git_result = std.process.run(allocator, io, .{
        .argv = &.{ "git", "ls-files", "-z", "--cached", "--others", "--exclude-standard" },
        .cwd = .{ .path = cwd },
    }) catch return walk.collectEntries(allocator, io, dir);
    defer allocator.free(git_result.stdout);
    defer allocator.free(git_result.stderr);

    switch (git_result.term) {
        .exited => |code| {
            if (code == 0) {
                const lines = try git.collectNulDelimitedLines(allocator, git_result.stdout);
                return git.collectEntries(allocator, io, cwd, dir, lines);
            }
        },
        else => {},
    }

    return walk.collectEntries(allocator, io, dir);
}

test {
    _ = git;
    _ = walk;
}
