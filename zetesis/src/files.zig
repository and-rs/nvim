const std = @import("std");

pub fn collectProjectFiles(allocator: std.mem.Allocator, io: std.Io, cwd: []const u8) ![]const []const u8 {
    const git_result = try std.process.run(allocator, io, .{
        .argv = &.{ "git", "ls-files", "--cached", "--others", "--exclude-standard" },
        .cwd = .{ .path = cwd },
    });
    defer allocator.free(git_result.stdout);
    defer allocator.free(git_result.stderr);

    switch (git_result.term) {
        .exited => |code| {
            if (code == 0) return collectLinesDuped(allocator, git_result.stdout);
        },
        else => {},
    }

    var dir = try std.Io.Dir.openDir(.cwd(), io, cwd, .{ .iterate = true });
    defer dir.close(io);
    return walkDir(allocator, io, dir);
}

fn walkDir(allocator: std.mem.Allocator, io: std.Io, dir: std.Io.Dir) ![]const []const u8 {
    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var lines: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit(allocator);
    }

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (ignoredPath(entry.path)) continue;
        try lines.append(allocator, try allocator.dupe(u8, entry.path));
    }

    std.mem.sort([]const u8, lines.items, {}, lessThan);
    return lines.toOwnedSlice(allocator);
}

fn ignoredPath(path: []const u8) bool {
    return std.mem.eql(u8, path, ".git") or std.mem.startsWith(u8, path, ".git/");
}

fn collectLinesDuped(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    var lines: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit(allocator);
    }

    var iter = std.mem.splitScalar(u8, std.mem.trim(u8, input, "\n"), '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, try allocator.dupe(u8, line));
    }

    return lines.toOwnedSlice(allocator);
}

fn lessThan(_: void, left: []const u8, right: []const u8) bool {
    return std.mem.order(u8, left, right) == .lt;
}

test "collect lines drops blanks and duplicates text" {
    const lines = try collectLinesDuped(std.testing.allocator, "a.zig\n\nb.zig\n");
    defer {
        for (lines) |line| std.testing.allocator.free(line);
        std.testing.allocator.free(lines);
    }

    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("a.zig", lines[0]);
    try std.testing.expectEqualStrings("b.zig", lines[1]);
}

test "walk files falls back and skips dot git" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.createDir(io, "src", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "src/main.zig", .data = "" });
    try tmp.dir.writeFile(io, .{ .sub_path = "README.md", .data = "" });
    try tmp.dir.createDir(io, ".git", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = ".git/config", .data = "" });

    var dir = try std.Io.Dir.openDir(tmp.dir, io, ".", .{ .iterate = true });
    defer dir.close(io);

    const lines = try walkDir(std.testing.allocator, io, dir);
    defer {
        for (lines) |line| std.testing.allocator.free(line);
        std.testing.allocator.free(lines);
    }

    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("README.md", lines[0]);
    try std.testing.expectEqualStrings("src/main.zig", lines[1]);
}
