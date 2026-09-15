const std = @import("std");

pub const Result = struct {
    score: i32,
    indexes: []usize = &.{},
};

pub fn hasUpper(text: []const u8) bool {
    for (text) |byte| if (std.ascii.isUpper(byte)) return true;
    return false;
}

pub fn score(text: []const u8, query: []const u8, case_sensitive: bool) ?i32 {
    if (query.len == 0) return 0;
    if (query.len > text.len) return null;

    var cursor: usize = 0;
    var previous: ?usize = null;
    var total: i32 = 0;
    for (query) |needle| {
        const index = findByte(text, cursor, needle, case_sensitive) orelse return null;
        total += 16;
        const bonus = boundaryBonus(text, index);
        total += if (previous == null) bonus * 2 else bonus;
        if (previous) |last| {
            const gap = index - last - 1;
            if (gap == 0) total += 8 else total -= @as(i32, @intCast(@min(gap, 32)));
        }
        previous = index;
        cursor = index + 1;
    }
    return total;
}

pub fn match(allocator: std.mem.Allocator, text: []const u8, query: []const u8, case_sensitive: bool) !?Result {
    const total = score(text, query, case_sensitive) orelse return null;
    if (query.len == 0) return .{ .score = total };

    const indexes = try allocator.alloc(usize, query.len);
    errdefer allocator.free(indexes);
    var cursor: usize = 0;
    for (query, 0..) |needle, i| {
        const index = findByte(text, cursor, needle, case_sensitive) orelse unreachable;
        indexes[i] = index;
        cursor = index + 1;
    }
    return .{ .score = total, .indexes = indexes };
}

pub fn deinit(result: *Result, allocator: std.mem.Allocator) void {
    if (result.indexes.len > 0) allocator.free(result.indexes);
    result.* = undefined;
}

fn findByte(text: []const u8, start: usize, needle: u8, case_sensitive: bool) ?usize {
    if (case_sensitive) return std.mem.indexOfScalarPos(u8, text, start, needle);
    const lower = std.ascii.toLower(needle);
    for (text[start..], start..) |byte, index| {
        if (std.ascii.toLower(byte) == lower) return index;
    }
    return null;
}

fn boundaryBonus(text: []const u8, index: usize) i32 {
    if (index == 0) return 8;
    const previous = text[index - 1];
    const current = text[index];
    if (previous == '/' or previous == '\\' or previous == '-' or previous == '_' or previous == '.' or previous == ' ') return 8;
    if (std.ascii.isLower(previous) and std.ascii.isUpper(current)) return 7;
    return 0;
}
