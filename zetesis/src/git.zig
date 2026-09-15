const std = @import("std");

pub const GitStatus = enum {
    none,
    modified,
    added,
    untracked,
    deleted,
    renamed,
};

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

pub fn parseStatusMap(allocator: std.mem.Allocator, status_output: []const u8) !std.StringHashMap(GitStatus) {
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
    var map = try parseStatusMap(allocator, status_output);
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
