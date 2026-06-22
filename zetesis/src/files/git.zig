const std = @import("std");
const Row = @import("../picker/row.zig");

pub const Entry = struct {
    path: []const u8,
    git_status: Row.GitStatus = .none,
};

pub fn collectEntries(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: []const u8,
    dir: std.Io.Dir,
    lines: []const []const u8,
) ![]const Entry {
    const filtered = try filterExistingFiles(allocator, io, dir, lines);
    errdefer {
        for (filtered) |line| allocator.free(line);
        allocator.free(filtered);
    }

    const status_result = try std.process.run(allocator, io, .{
        .argv = &.{ "git", "status", "--porcelain=v1", "-z" },
        .cwd = .{ .path = cwd },
    });
    defer allocator.free(status_result.stdout);
    defer allocator.free(status_result.stderr);

    switch (status_result.term) {
        .exited => |code| if (code != 0) return entriesFromLines(allocator, filtered),
        else => return entriesFromLines(allocator, filtered),
    }

    return entriesFromGitStatus(allocator, filtered, status_result.stdout);
}

pub fn entriesFromLines(allocator: std.mem.Allocator, lines: []const []const u8) ![]const Entry {
    var entries: std.ArrayList(Entry) = .empty;
    errdefer entries.deinit(allocator);
    defer allocator.free(lines);
    for (lines) |line| try entries.append(allocator, .{ .path = line });
    return entries.toOwnedSlice(allocator);
}

pub fn collectLinesDuped(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
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

fn entriesFromGitStatus(allocator: std.mem.Allocator, lines: []const []const u8, status_output: []const u8) ![]const Entry {
    var status_map = try gitStatusMap(allocator, status_output);
    defer status_map.deinit();

    var entries: std.ArrayList(Entry) = .empty;
    errdefer entries.deinit(allocator);
    defer allocator.free(lines);
    for (lines) |line| {
        try entries.append(allocator, .{ .path = line, .git_status = status_map.get(line) orelse .none });
    }
    return entries.toOwnedSlice(allocator);
}

fn gitStatusMap(allocator: std.mem.Allocator, status_output: []const u8) !std.StringHashMap(Row.GitStatus) {
    var map = std.StringHashMap(Row.GitStatus).init(allocator);
    errdefer map.deinit();

    var index: usize = 0;
    while (index < status_output.len) {
        if (index + 3 > status_output.len) break;
        const x = status_output[index];
        const y = status_output[index + 1];
        const path_start = index + 3;
        const path_end = std.mem.indexOfScalarPos(u8, status_output, path_start, 0) orelse status_output.len;
        const status_path = status_output[path_start..path_end];
        index = path_end + 1;
        const status = gitStatusFromCode(x, y);
        if (status == .renamed) {
            const old_end = std.mem.indexOfScalarPos(u8, status_output, index, 0) orelse status_output.len;
            index = old_end + 1;
        }
        try map.put(status_path, status);
    }

    return map;
}

fn gitStatusForPath(allocator: std.mem.Allocator, status_output: []const u8, path: []const u8) !Row.GitStatus {
    var map = try gitStatusMap(allocator, status_output);
    defer map.deinit();
    return map.get(path) orelse .none;
}

fn gitStatusFromCode(x: u8, y: u8) Row.GitStatus {
    if (x == '?' and y == '?') return .untracked;
    if (x == 'R' or y == 'R') return .renamed;
    if (x == 'D' or y == 'D') return .deleted;
    if (x == 'A' or y == 'A') return .added;
    if (x == 'M' or y == 'M') return .modified;
    return .none;
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

test "git status parser maps porcelain status" {
    const output = " M src/main.zig\x00A  src/new.zig\x00?? scratch.txt\x00R  new.txt\x00old.txt\x00";
    try std.testing.expectEqual(Row.GitStatus.modified, try gitStatusForPath(std.testing.allocator, output, "src/main.zig"));
    try std.testing.expectEqual(Row.GitStatus.added, try gitStatusForPath(std.testing.allocator, output, "src/new.zig"));
    try std.testing.expectEqual(Row.GitStatus.untracked, try gitStatusForPath(std.testing.allocator, output, "scratch.txt"));
    try std.testing.expectEqual(Row.GitStatus.renamed, try gitStatusForPath(std.testing.allocator, output, "new.txt"));
    try std.testing.expectEqual(Row.GitStatus.none, try gitStatusForPath(std.testing.allocator, output, "old.txt"));
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
