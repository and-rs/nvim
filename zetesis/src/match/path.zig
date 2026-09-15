const std = @import("std");
const fuzzy = @import("fuzzy.zig");

pub const Options = struct {
    current_file: ?[]const u8 = null,
    plain: bool = false,
};

pub const Result = fuzzy.Result;

pub fn score(path: []const u8, query: []const u8, options: Options) ?i32 {
    if (query.len == 0) return contextScore(path, 0, options);
    const case_sensitive = fuzzy.hasUpper(query);
    if (options.plain) return contextScore(path, fuzzy.score(path, query, case_sensitive) orelse return null, options);

    if (std.mem.indexOfAny(u8, query, "/\\") != null) return contextScore(path, strictPathScore(path, query, case_sensitive) orelse return null, options);

    var best = fuzzy.score(path, query, case_sensitive) orelse return null;
    const filename = std.fs.path.basename(path);
    if (fuzzy.score(filename, query, case_sensitive)) |filename_score| best = @max(best, filename_score + 48);
    return contextScore(path, best, options);
}

pub fn match(allocator: std.mem.Allocator, path: []const u8, query: []const u8, options: Options) !?Result {
    const total = score(path, query, options) orelse return null;
    if (query.len == 0) return .{ .score = total };

    const case_sensitive = fuzzy.hasUpper(query);
    const text = if (!options.plain and std.mem.indexOfAny(u8, query, "/\\") == null and fuzzy.score(std.fs.path.basename(path), query, case_sensitive) != null) std.fs.path.basename(path) else path;
    var result = (try fuzzy.match(allocator, text, query, case_sensitive)).?;
    result.score = total;
    if (@intFromPtr(text.ptr) != @intFromPtr(path.ptr)) {
        const offset = @intFromPtr(text.ptr) - @intFromPtr(path.ptr);
        for (result.indexes) |*index| index.* += offset;
    }
    return result;
}

fn contextScore(path: []const u8, base: i32, options: Options) i32 {
    var result = base;
    if (options.current_file) |current| {
        if (std.mem.eql(u8, path, current)) result -= 1_000;
    }
    return result;
}

fn strictPathScore(path: []const u8, query: []const u8, case_sensitive: bool) ?i32 {
    var path_parts = std.mem.splitAny(u8, path, "/\\");
    var query_parts = std.mem.splitAny(u8, query, "/\\");
    var total: i32 = 0;
    while (query_parts.next()) |part| {
        if (part.len == 0) continue;
        var found = false;
        while (path_parts.next()) |component| {
            if (fuzzy.score(component, part, case_sensitive)) |part_score| {
                total += part_score + 8;
                found = true;
                break;
            }
        }
        if (!found) return null;
    }
    return total;
}
