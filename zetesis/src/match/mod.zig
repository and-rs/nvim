const std = @import("std");

pub const RankOptions = struct {
    case_sensitive: bool = false,
    plain: bool = false,
    current_file: ?[]const u8 = null,
};

pub const ScoreBreakdown = struct {
    fuzzy: f64 = 0,
    filename_boost: f64 = 0,
    exact_filename_boost: f64 = 0,
    current_file_penalty: f64 = 0,

    pub fn total(self: ScoreBreakdown) f64 {
        return self.fuzzy + self.filename_boost + self.exact_filename_boost + self.current_file_penalty;
    }
};

pub const RankedLine = struct {
    text: []const u8,
    source_index: usize,
    score: ScoreBreakdown,
    match_indexes: []const usize = &.{},
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

pub fn rank(haystack: []const u8, needles: []const []const u8, opts: RankOptions) ?ScoreBreakdown {
    if (haystack.len == 0 or needles.len == 0) return null;

    const filename = if (opts.plain) null else std.fs.path.basename(haystack);
    var total: ScoreBreakdown = .{};

    for (needles) |needle| {
        const strict_path = !opts.plain and hasSeparator(needle);
        if (rankNeedle(haystack, filename, needle, opts.case_sensitive, strict_path)) |score| {
            total.fuzzy += score.fuzzy;
            total.filename_boost += score.filename_boost;
            total.exact_filename_boost += score.exact_filename_boost;
        } else return null;
    }

    return applyContextScore(haystack, total, opts);
}

pub fn rankNeedle(
    haystack: []const u8,
    filename: ?[]const u8,
    needle: []const u8,
    case_sensitive: bool,
    strict_path: bool,
) ?ScoreBreakdown {
    if (haystack.len == 0 or needle.len == 0) return null;

    if (strict_path) {
        return .{ .fuzzy = rankStrictPath(haystack, needle, case_sensitive) orelse return null };
    }

    if (filename) |name| {
        if (scoreSubsequence(name, needle, case_sensitive)) |score| {
            return .{
                .fuzzy = score,
                .filename_boost = score * 1.5 + if (contains(name, needle, case_sensitive)) score * 3.0 else 0,
                .exact_filename_boost = if (equals(name, needle, case_sensitive)) score * 7.5 else 0,
            };
        }
    }

    return .{ .fuzzy = scoreSubsequence(haystack, needle, case_sensitive) orelse return null };
}

pub fn rankAll(
    allocator: std.mem.Allocator,
    lines: []const []const u8,
    needles: []const []const u8,
    opts: RankOptions,
) ![]RankedLine {
    var ranked: std.ArrayList(RankedLine) = .empty;
    for (lines, 0..) |line, index| {
        if (needles.len == 0) {
            try ranked.append(allocator, .{ .text = line, .source_index = index, .score = applyContextScore(line, .{}, opts) });
        } else if (rank(line, needles, opts)) |score| {
            try ranked.append(allocator, .{ .text = line, .source_index = index, .score = score, .match_indexes = try matchIndexes(allocator, line, needles, opts.case_sensitive) });
        }
    }
    std.mem.sort(RankedLine, ranked.items, {}, compareRankedLine);
    return ranked.toOwnedSlice(allocator);
}

pub fn rankTop(
    allocator: std.mem.Allocator,
    lines: []const []const u8,
    needles: []const []const u8,
    opts: RankOptions,
    limit: usize,
) ![]RankedLine {
    if (limit == 0) return &.{};

    var ranked: std.ArrayList(RankedLine) = .empty;
    for (lines, 0..) |line, index| {
        const score = if (needles.len == 0) applyContextScore(line, .{}, opts) else rank(line, needles, opts) orelse continue;
        try insertBounded(allocator, &ranked, .{ .text = line, .source_index = index, .score = score }, limit);
    }

    if (needles.len != 0) {
        for (ranked.items) |*line| {
            line.match_indexes = try matchIndexes(allocator, line.text, needles, opts.case_sensitive);
        }
    }

    return ranked.toOwnedSlice(allocator);
}

fn insertBounded(allocator: std.mem.Allocator, ranked: *std.ArrayList(RankedLine), candidate: RankedLine, limit: usize) !void {
    var index: usize = 0;
    while (index < ranked.items.len) : (index += 1) {
        if (compareRankedLine({}, candidate, ranked.items[index])) break;
    }

    if (index >= limit) return;
    if (ranked.items.len < limit) {
        try ranked.append(allocator, candidate);
    } else {
        _ = ranked.pop();
        try ranked.append(allocator, candidate);
    }

    var move_index = ranked.items.len - 1;
    while (move_index > index) : (move_index -= 1) {
        ranked.items[move_index] = ranked.items[move_index - 1];
    }
    ranked.items[index] = candidate;
}

fn applyContextScore(line: []const u8, score: ScoreBreakdown, opts: RankOptions) ScoreBreakdown {
    var result = score;
    if (opts.current_file) |current_file| {
        if (std.mem.eql(u8, line, current_file)) {
            result.current_file_penalty -= 1000.0;
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

fn matchIndexes(allocator: std.mem.Allocator, haystack: []const u8, needles: []const []const u8, case_sensitive: bool) ![]const usize {
    var indexes: std.ArrayList(usize) = .empty;
    errdefer indexes.deinit(allocator);

    for (needles) |needle| {
        var start: usize = 0;
        var iter = std.mem.splitAny(u8, needle, "/\\");
        while (iter.next()) |segment| {
            if (segment.len == 0) continue;
            for (segment) |byte| {
                const found = findByte(haystack, start, byte, case_sensitive) orelse break;
                try indexes.append(allocator, found);
                start = found + 1;
            }
        }
    }

    std.mem.sort(usize, indexes.items, {}, lessThanUsize);
    return indexes.toOwnedSlice(allocator);
}

fn lessThanUsize(_: void, left: usize, right: usize) bool {
    return left < right;
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

fn contains(haystack: []const u8, needle: []const u8, case_sensitive: bool) bool {
    if (case_sensitive) return std.mem.indexOf(u8, haystack, needle) != null;
    return std.ascii.indexOfIgnoreCase(haystack, needle) != null;
}

fn compareRankedLine(_: void, left: RankedLine, right: RankedLine) bool {
    const left_total = left.score.total();
    const right_total = right.score.total();
    if (left_total == right_total) return std.mem.lessThan(u8, left.text, right.text);
    return left_total > right_total;
}

test "filename priority" {
    const testing = std.testing;
    const needles = &.{"make"};
    const direct = (rank("GNUmakefile", needles, .{}) orelse ScoreBreakdown{}).total();
    const nested = (rank("source/blender/makesdna/DNA_genfile.h", needles, .{}) orelse ScoreBreakdown{}).total();
    try testing.expect(direct > nested);
}

test "contiguous filename match beats separated filename match" {
    const needles = &.{"mu"};
    const contiguous = (rank("lua/plugins/tmux.lua", needles, .{}) orelse ScoreBreakdown{}).total();
    const separated = (rank("lua/config/map.lua", needles, .{}) orelse ScoreBreakdown{}).total();
    try std.testing.expect(contiguous > separated);
}

test "strict path" {
    const testing = std.testing;
    const needles = &.{"a/m/f/b/baz"};
    try testing.expect(rank("app/models/foo/bar/baz.rb", needles, .{}) != null);
    try testing.expect(rank("app/monsters/dungeon/foo/bar/baz.rb", needles, .{}) == null);
}

test "score breakdown keeps filename and exact boosts visible" {
    const testing = std.testing;
    const ranked = rank("src/main.zig", &.{"main.zig"}, .{}) orelse return error.TestUnexpectedResult;
    try testing.expect(ranked.fuzzy > 0);
    try testing.expect(ranked.filename_boost > 0);
    try testing.expect(ranked.exact_filename_boost > 0);
    try testing.expect(ranked.total() > ranked.fuzzy);
}

test "current file penalty lowers total only" {
    const testing = std.testing;
    const ranked = rank("src/main.zig", &.{"main"}, .{ .current_file = "src/main.zig" }) orelse return error.TestUnexpectedResult;
    try testing.expect(ranked.fuzzy > 0);
    try testing.expect(ranked.current_file_penalty < 0);
}

test "ranked lines keep source index and match positions" {
    const ranked = try rankAll(std.testing.allocator, &.{ "src/main.zig", "README.md" }, &.{"main"}, .{});
    defer {
        for (ranked) |line| std.testing.allocator.free(line.match_indexes);
        std.testing.allocator.free(ranked);
    }

    try std.testing.expectEqual(@as(usize, 0), ranked[0].source_index);
    try std.testing.expectEqual(@as(usize, 4), ranked[0].match_indexes.len);
    try std.testing.expectEqual(@as(usize, 4), ranked[0].match_indexes[0]);
}

test "rankTop keeps only best matches" {
    const ranked = try rankTop(std.testing.allocator, &.{ "src/main.zig", "src/matcher.zig", "README.md" }, &.{"zig"}, .{}, 1);
    defer {
        for (ranked) |line| std.testing.allocator.free(line.match_indexes);
        std.testing.allocator.free(ranked);
    }

    try std.testing.expectEqual(@as(usize, 1), ranked.len);
    try std.testing.expect(ranked[0].match_indexes.len > 0);
}
