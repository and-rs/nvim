const std = @import("std");

pub const Entry = struct {
    path: []const u8,
    git_status: GitStatus = .none,
};

pub const GitStatus = enum {
    none,
    modified,
    added,
    untracked,
    deleted,
    renamed,
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

pub fn collectNulDelimitedLines(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    var lines: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (lines.items) |line| allocator.free(line);
        lines.deinit(allocator);
    }

    var iter = std.mem.splitScalar(u8, input, 0);
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, try allocator.dupe(u8, line));
    }

    return lines.toOwnedSlice(allocator);
}

pub fn filterExistingFiles(
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
        const stat = dir.statFile(io, line, .{}) catch |err| switch (err) {
            error.FileNotFound => {
                allocator.free(line);
                continue;
            },
            else => return err,
        };
        if (stat.kind != .file) {
            allocator.free(line);
            continue;
        }
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

fn gitStatusMap(allocator: std.mem.Allocator, status_output: []const u8) !std.StringHashMap(GitStatus) {
    var map = std.StringHashMap(GitStatus).init(allocator);
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

pub fn gitStatusForPath(allocator: std.mem.Allocator, status_output: []const u8, path: []const u8) !GitStatus {
    var map = try gitStatusMap(allocator, status_output);
    defer map.deinit();
    return map.get(path) orelse .none;
}

fn gitStatusFromCode(x: u8, y: u8) GitStatus {
    if (x == '?' and y == '?') return .untracked;
    if (x == 'R' or y == 'R') return .renamed;
    if (x == 'D' or y == 'D') return .deleted;
    if (x == 'A' or y == 'A') return .added;
    if (x == 'M' or y == 'M') return .modified;
    return .none;
}
