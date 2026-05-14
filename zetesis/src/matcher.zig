const std = @import("std");

pub const RankOptions = struct {
    case_sensitive: bool = false,
    plain: bool = false,
    current_file: ?[]const u8 = null,
};

pub const RankedLine = struct {
    text: []const u8,
    score: f64,
};

pub fn hasUpper(text: []const u8) bool {
    for (text) |byte| {
        if (std.ascii.isUpper(byte)) return true;
    }
    return false;
}

pub fn hasSeparator(text: []const u8) bool {
    for (text) |byte| {
        if (byte == '/' or byte == '\\') return true;
    }
    return false;
}

pub fn splitQuery(allocator: std.mem.Allocator, query: []const u8) ![]const []const u8 {
    var needles: std.ArrayList([]const u8) = .empty;
    var iter = std.mem.tokenizeAny(u8, query, " \t");
    while (iter.next()) |needle| {
        try needles.append(allocator, needle);
    }
    return needles.toOwnedSlice(allocator);
}

pub fn rank(haystack: []const u8, needles: []const []const u8, opts: RankOptions) ?f64 {
    if (haystack.len == 0 or needles.len == 0) return null;

    const filename = if (opts.plain) null else std.fs.path.basename(haystack);
    var total: f64 = 0;

    for (needles) |needle| {
        const strict_path = !opts.plain and hasSeparator(needle);
        if (rankNeedle(haystack, filename, needle, opts.case_sensitive, strict_path)) |score| {
            total += score;
        } else return null;
    }

    return total;
}

pub fn rankNeedle(
    haystack: []const u8,
    filename: ?[]const u8,
    needle: []const u8,
    case_sensitive: bool,
    strict_path: bool,
) ?f64 {
    if (haystack.len == 0 or needle.len == 0) return null;

    if (strict_path) {
        return rankStrictPath(haystack, needle, case_sensitive);
    }

    if (filename) |name| {
        if (scoreSubsequence(name, needle, case_sensitive)) |score| {
            const exact_boost: f64 = if (equals(name, needle, case_sensitive)) 4.0 else 1.0;
            return score * 2.5 * exact_boost;
        }
    }

    return scoreSubsequence(haystack, needle, case_sensitive);
}

pub fn rankAndSort(
    allocator: std.mem.Allocator,
    lines: []const []const u8,
    needles: []const []const u8,
    opts: RankOptions,
) ![]RankedLine {
    var ranked: std.ArrayList(RankedLine) = .empty;
    for (lines) |line| {
        if (needles.len == 0) {
            try ranked.append(allocator, .{ .text = line, .score = applyContextScore(line, 0, opts) });
        } else if (rank(line, needles, opts)) |score| {
            try ranked.append(allocator, .{ .text = line, .score = applyContextScore(line, score, opts) });
        }
    }
    std.mem.sort(RankedLine, ranked.items, {}, compareRankedLine);
    return ranked.toOwnedSlice(allocator);
}

fn applyContextScore(line: []const u8, score: f64, opts: RankOptions) f64 {
    var result = score;
    if (opts.current_file) |current_file| {
        if (std.mem.eql(u8, line, current_file)) {
            result -= 1000.0;
        }
    }
    return result;
}

fn rankStrictPath(haystack: []const u8, needle: []const u8, case_sensitive: bool) ?f64 {
    var start: usize = 0;

    while (start < haystack.len) {
        var haystack_index = start;
        var total: f64 = 0;
        var matched = true;
        var iter = std.mem.splitAny(u8, needle, "/\\");

        while (iter.next()) |segment| {
            if (segment.len == 0) continue;
            if (haystack_index >= haystack.len) {
                matched = false;
                break;
            }

            const end = pathSegmentEnd(haystack, haystack_index);
            const path_segment = haystack[haystack_index..end];
            if (scoreSubsequence(path_segment, segment, case_sensitive)) |score| {
                total += score + 3.0;
                haystack_index = if (end < haystack.len) end + 1 else end;
            } else {
                matched = false;
                break;
            }
        }

        if (matched) return total;

        const end = pathSegmentEnd(haystack, start);
        start = if (end < haystack.len) end + 1 else end;
    }

    return null;
}

fn pathSegmentEnd(text: []const u8, start: usize) usize {
    var index = start;
    while (index < text.len) : (index += 1) {
        if (text[index] == '/' or text[index] == '\\') break;
    }
    return index;
}

fn scoreSubsequence(haystack: []const u8, needle: []const u8, case_sensitive: bool) ?f64 {
    var haystack_index: usize = 0;
    var previous_match: ?usize = null;
    var score: f64 = 0;

    for (needle) |needle_byte| {
        const found = findByte(haystack, haystack_index, needle_byte, case_sensitive) orelse return null;
        const gap = if (previous_match) |previous| found - previous - 1 else found;

        score += 1.0;
        if (found == 0) score += 2.0;
        if (isBoundary(haystack, found)) score += 1.5;
        if (gap == 0) score += 2.0 else score -= @as(f64, @floatFromInt(gap)) * 0.03;

        previous_match = found;
        haystack_index = found + 1;
    }

    const coverage = @as(f64, @floatFromInt(needle.len)) / @as(f64, @floatFromInt(haystack.len));
    return score + coverage * 5.0;
}

fn findByte(haystack: []const u8, start: usize, needle: u8, case_sensitive: bool) ?usize {
    if (case_sensitive) return std.mem.indexOfScalarPos(u8, haystack, start, needle);

    const lower = std.ascii.toLower(needle);
    for (haystack[start..], start..) |byte, index| {
        if (std.ascii.toLower(byte) == lower) return index;
    }
    return null;
}

fn isBoundary(text: []const u8, index: usize) bool {
    if (index == 0) return true;

    const previous = text[index - 1];
    const current = text[index];
    return previous == '/' or previous == '\\' or previous == '-' or previous == '_' or previous == '.' or
        (std.ascii.isLower(previous) and std.ascii.isUpper(current));
}

fn equals(a: []const u8, b: []const u8, case_sensitive: bool) bool {
    if (case_sensitive) return std.mem.eql(u8, a, b);
    return std.ascii.eqlIgnoreCase(a, b);
}

fn compareRankedLine(_: void, left: RankedLine, right: RankedLine) bool {
    if (left.score == right.score) return std.mem.lessThan(u8, left.text, right.text);
    return left.score > right.score;
}

test "filename priority" {
    const testing = std.testing;
    const needles = &.{"make"};
    const direct = rank("GNUmakefile", needles, .{}) orelse 0;
    const nested = rank("source/blender/makesdna/DNA_genfile.h", needles, .{}) orelse 0;
    try testing.expect(direct > nested);
}

test "strict path" {
    const testing = std.testing;
    const needles = &.{"a/m/f/b/baz"};
    try testing.expect(rank("app/models/foo/bar/baz.rb", needles, .{}) != null);
    try testing.expect(rank("app/monsters/dungeon/foo/bar/baz.rb", needles, .{}) == null);
}
