const std = @import("std");

pub fn collectProjectFiles(allocator: std.mem.Allocator, io: std.Io, cwd: []const u8) ![]const []const u8 {
    var dir = try std.Io.Dir.openDir(.cwd(), io, cwd, .{ .iterate = true });
    defer dir.close(io);

    const git_result = try std.process.run(allocator, io, .{
        .argv = &.{ "git", "ls-files", "--cached", "--others", "--exclude-standard" },
        .cwd = .{ .path = cwd },
    });
    defer allocator.free(git_result.stdout);
    defer allocator.free(git_result.stderr);

    switch (git_result.term) {
        .exited => |code| {
            if (code == 0) {
                const lines = try collectLinesDuped(allocator, git_result.stdout);
                return filterExistingFiles(allocator, io, dir, lines);
            }
        },
        else => {},
    }

    return walkDir(allocator, io, dir);
}

fn filterExistingFiles(
    allocator: std.mem.Allocator,
    io: std.Io,
    dir: std.Io.Dir,
    lines: []const []const u8,
) ![]const []const u8 {
    var filtered: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (filtered.items) |line| allocator.free(line);
        filtered.deinit(allocator);
    }
    defer allocator.free(lines);

    for (lines) |line| {
        dir.access(io, line, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                allocator.free(line);
                continue;
            },
            else => return err,
        };
        try filtered.append(allocator, line);
    }

    return filtered.toOwnedSlice(allocator);
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

test "git file collection skips deleted tracked files" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "keep.txt", .data = "keep\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "gone.txt", .data = "gone\n" });

    const init_result = try std.process.run(std.testing.allocator, io, .{
        .argv = &.{ "git", "init" },
        .cwd = .{ .dir = tmp.dir },
    });
    defer {
        std.testing.allocator.free(init_result.stdout);
        std.testing.allocator.free(init_result.stderr);
    }
    try std.testing.expectEqual(@as(u8, 0), init_result.term.exited);

    const add_result = try std.process.run(std.testing.allocator, io, .{
        .argv = &.{ "git", "add", "keep.txt", "gone.txt" },
        .cwd = .{ .dir = tmp.dir },
    });
    defer {
        std.testing.allocator.free(add_result.stdout);
        std.testing.allocator.free(add_result.stderr);
    }
    try std.testing.expectEqual(@as(u8, 0), add_result.term.exited);

    try tmp.dir.deleteFile(io, "gone.txt");
    try tmp.dir.writeFile(io, .{ .sub_path = "new.txt", .data = "new\n" });

    const git_result = try std.process.run(std.testing.allocator, io, .{
        .argv = &.{ "git", "ls-files", "--cached", "--others", "--exclude-standard" },
        .cwd = .{ .dir = tmp.dir },
    });
    defer {
        std.testing.allocator.free(git_result.stdout);
        std.testing.allocator.free(git_result.stderr);
    }

    const git_lines = try collectLinesDuped(std.testing.allocator, git_result.stdout);
    var dir = try std.Io.Dir.openDir(tmp.dir, io, ".", .{ .iterate = true });
    defer dir.close(io);

    const lines = try filterExistingFiles(std.testing.allocator, io, dir, git_lines);
    defer {
        for (lines) |line| std.testing.allocator.free(line);
        std.testing.allocator.free(lines);
    }

    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expect(
        (std.mem.eql(u8, lines[0], "keep.txt") and std.mem.eql(u8, lines[1], "new.txt")) or
            (std.mem.eql(u8, lines[0], "new.txt") and std.mem.eql(u8, lines[1], "keep.txt")),
    );
}