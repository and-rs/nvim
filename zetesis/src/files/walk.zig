const std = @import("std");
const git = @import("git.zig");

pub fn collectEntries(allocator: std.mem.Allocator, io: std.Io, dir: std.Io.Dir) ![]const git.Entry {
    const paths = try collect(allocator, io, dir);
    return git.entriesFromLines(allocator, paths);
}

pub fn collect(allocator: std.mem.Allocator, io: std.Io, dir: std.Io.Dir) ![]const []const u8 {
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
    const ignored_roots = [_][]const u8{
        ".git",
        ".cache",
        ".zig-cache",
        "node_modules",
    };
    for (ignored_roots) |root| {
        if (!std.mem.startsWith(u8, path, root)) continue;
        if (path.len == root.len or path[root.len] == '/') return true;
    }
    return false;
}

fn lessThan(_: void, left: []const u8, right: []const u8) bool {
    return std.mem.order(u8, left, right) == .lt;
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
    try tmp.dir.createDir(io, "node_modules", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "node_modules/package.js", .data = "" });
    try tmp.dir.createDir(io, ".zig-cache", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = ".zig-cache/cache.bin", .data = "" });

    var dir = try std.Io.Dir.openDir(tmp.dir, io, ".", .{ .iterate = true });
    defer dir.close(io);

    const lines = try collect(std.testing.allocator, io, dir);
    defer {
        for (lines) |line| std.testing.allocator.free(line);
        std.testing.allocator.free(lines);
    }

    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("README.md", lines[0]);
    try std.testing.expectEqualStrings("src/main.zig", lines[1]);
}
