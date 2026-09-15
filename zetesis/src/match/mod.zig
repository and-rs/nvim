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

pub const QueryTerm = union(enum) {
    fuzzy: []const u8,
    basename: []const u8,
    extension: []const u8,
    literal: []const u8,
};

pub fn parseQuery(allocator: std.mem.Allocator, query: []const u8) ![]const QueryTerm {
    var terms: std.ArrayList(QueryTerm) = .empty;
    var iter = std.mem.tokenizeAny(u8, query, " \t");
    while (iter.next()) |token| {
        const term: QueryTerm = if (token.len > 1 and token[0] == '%') .{ .literal = token[1..] } else if (token.len > 1 and token[0] == '>') .{ .basename = token[1..] } else if (token.len > 1 and token[0] == '#') .{ .extension = token[1..] } else .{ .fuzzy = token };
        try terms.append(allocator, term);
    }
    return terms.toOwnedSlice(allocator);
}

pub fn rankQuery(haystack: []const u8, terms: []const QueryTerm, opts: RankOptions) ?ScoreBreakdown {
    if (haystack.len == 0) return null;
    var total: ScoreBreakdown = .{};
    const filename = std.fs.path.basename(haystack);
    for (terms) |term| switch (term) {
        .fuzzy => |needle| {
            const strict_path = !opts.plain and hasSeparator(needle);
            const score = rankNeedle(haystack, if (opts.plain) null else filename, needle, opts.case_sensitive, strict_path) orelse return null;
            total.fuzzy += score.fuzzy;
            total.filename_boost += score.filename_boost;
            total.exact_filename_boost += score.exact_filename_boost;
        },
        .basename => |needle| {
            const fuzzy = scoreSubsequence(filename, needle, opts.case_sensitive) orelse return null;
            const score = componentScore(haystack, filename, filename, needle, opts.case_sensitive, fuzzy);
            total.fuzzy += score.fuzzy;
            total.filename_boost += score.filename_boost;
            total.exact_filename_boost += score.exact_filename_boost;
        },
        .extension => |extension| {
            if (!endsWithExtension(filename, extension, opts.case_sensitive or hasUpper(extension))) return null;
            total.filename_boost += 1;
        },
        .literal => |literal| {
            if (indexOf(haystack, literal, opts.case_sensitive or hasUpper(literal)) == null) return null;
            total.filename_boost += 1;
        },
    };
    return applyContextScore(haystack, total, opts);
}

pub fn rankQueryTop(allocator: std.mem.Allocator, lines: []const []const u8, terms: []const QueryTerm, opts: RankOptions, limit: usize) ![]RankedLine {
    if (limit == 0) return &.{};
    var ranked: std.ArrayList(RankedLine) = .empty;
    for (lines, 0..) |line, index| {
        const score = if (terms.len == 0) applyContextScore(line, .{}, opts) else rankQuery(line, terms, opts) orelse continue;
        try insertBounded(allocator, &ranked, .{ .text = line, .source_index = index, .score = score }, limit);
    }
    for (ranked.items) |*line| line.match_indexes = try queryMatchIndexes(allocator, line.text, terms, opts.case_sensitive);
    return ranked.toOwnedSlice(allocator);
}

fn queryMatchIndexes(allocator: std.mem.Allocator, haystack: []const u8, terms: []const QueryTerm, case_sensitive: bool) ![]const usize {
    var indexes: std.ArrayList(usize) = .empty;
    errdefer indexes.deinit(allocator);
    for (terms) |term| switch (term) {
        .fuzzy => |needle| {
            const component = if (bestComponentMatch(haystack, std.fs.path.basename(haystack), needle, case_sensitive)) |match| match.component else haystack;
            try appendSubsequenceIndexes(&indexes, allocator, component, needle, case_sensitive, @intFromPtr(component.ptr) - @intFromPtr(haystack.ptr));
        },
        .basename => |needle| try appendSubsequenceIndexes(&indexes, allocator, std.fs.path.basename(haystack), needle, case_sensitive, haystack.len - std.fs.path.basename(haystack).len),
        .literal => |literal| if (indexOf(haystack, literal, case_sensitive or hasUpper(literal))) |start| for (0..literal.len) |i| try indexes.append(allocator, start + i),
        .extension => {},
    };
    std.mem.sort(usize, indexes.items, {}, lessThanUsize);
    var write: usize = 0;
    for (indexes.items) |index| {
        if (write == 0 or indexes.items[write - 1] != index) {
            indexes.items[write] = index;
            write += 1;
        }
    }
    indexes.shrinkRetainingCapacity(write);
    return indexes.toOwnedSlice(allocator);
}

fn indexOf(haystack: []const u8, needle: []const u8, case_sensitive: bool) ?usize {
    if (case_sensitive) return std.mem.indexOf(u8, haystack, needle);
    return std.ascii.indexOfIgnoreCase(haystack, needle);
}

fn endsWithExtension(filename: []const u8, extension: []const u8, case_sensitive: bool) bool {
    if (extension.len == 0) return false;
    if (extension[0] == '.') {
        if (extension.len > filename.len) return false;
        return equals(filename[filename.len - extension.len ..], extension, case_sensitive);
    }
    if (extension.len + 1 > filename.len) return false;
    const start = filename.len - extension.len - 1;
    return filename[start] == '.' and equals(filename[start + 1 ..], extension, case_sensitive);
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

    if (bestComponentMatch(haystack, filename orelse "", needle, case_sensitive)) |match| return match.score;

    return .{ .fuzzy = scoreSubsequence(haystack, needle, case_sensitive) orelse return null };
}

const ComponentMatch = struct {
    component: []const u8,
    score: ScoreBreakdown,
};

fn bestComponentMatch(haystack: []const u8, filename: []const u8, needle: []const u8, case_sensitive: bool) ?ComponentMatch {
    var best: ?ComponentMatch = null;
    var components = std.mem.splitAny(u8, haystack, "/\\");
    while (components.next()) |component| {
        const fuzzy = scoreSubsequence(component, needle, case_sensitive) orelse continue;
        const score = componentScore(haystack, component, filename, needle, case_sensitive, fuzzy);
        if (best == null or score.total() > best.?.score.total()) best = .{ .component = component, .score = score };
    }
    return best;
}

fn componentScore(haystack: []const u8, component: []const u8, filename: []const u8, needle: []const u8, case_sensitive: bool, fuzzy: f64) ScoreBreakdown {
    var score: ScoreBreakdown = .{ .fuzzy = fuzzy };
    if (std.mem.eql(u8, component, filename)) {
        score.filename_boost = fuzzy * 1.5 + if (contains(component, needle, case_sensitive)) fuzzy * 3.0 else 0;
        if (startsWith(component, needle, case_sensitive)) score.filename_boost += 300.0;
        if (equals(component, needle, case_sensitive)) score.exact_filename_boost = fuzzy * 7.5;
        return score;
    }
    if (equals(component, needle, case_sensitive)) {
        score.exact_filename_boost = fuzzy * 7.5 + componentProximityBonus(haystack, component);
    }
    return score;
}

fn componentProximityBonus(haystack: []const u8, component: []const u8) f64 {
    const offset = @intFromPtr(component.ptr) - @intFromPtr(haystack.ptr);
    const suffix = haystack[offset + component.len ..];
    var distance: usize = 0;
    var in_component = false;
    for (suffix) |byte| {
        if (byte == '/' or byte == '\\') {
            in_component = false;
        } else if (!in_component) {
            in_component = true;
            distance += 1;
        }
    }
    return if (distance == 0) 0 else 100.0 / @as(f64, @floatFromInt(distance));
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

fn rankStrictPath(
    haystack: []const u8,
    needle: []const u8,
    case_sensitive: bool,
) ?f64 {
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

fn pathSegmentEnd(
    text: []const u8,
    start: usize,
) usize {
    var index = start;
    while (index < text.len) : (index += 1) {
        if (text[index] == '/' or text[index] == '\\') break;
    }
    return index;
}

fn scoreSubsequence(
    haystack: []const u8,
    needle: []const u8,
    case_sensitive: bool,
) ?f64 {
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

pub fn matchIndexes(
    allocator: std.mem.Allocator,
    haystack: []const u8,
    needles: []const []const u8,
    case_sensitive: bool,
) ![]const usize {
    var indexes: std.ArrayList(usize) = .empty;
    errdefer indexes.deinit(allocator);

    for (needles) |needle| {
        const component = if (bestComponentMatch(haystack, std.fs.path.basename(haystack), needle, case_sensitive)) |match| match.component else haystack;
        const offset = @intFromPtr(component.ptr) - @intFromPtr(haystack.ptr);
        try appendSubsequenceIndexes(&indexes, allocator, component, needle, case_sensitive, offset);
    }

    std.mem.sort(usize, indexes.items, {}, lessThanUsize);
    return indexes.toOwnedSlice(allocator);
}

fn appendSubsequenceIndexes(
    indexes: *std.ArrayList(usize),
    allocator: std.mem.Allocator,
    haystack: []const u8,
    needle: []const u8,
    case_sensitive: bool,
    offset: usize,
) !void {
    var start: usize = 0;
    for (needle) |byte| {
        const found = findByte(haystack, start, byte, case_sensitive) orelse return;
        try indexes.append(allocator, offset + found);
        start = found + 1;
    }
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

fn startsWith(haystack: []const u8, needle: []const u8, case_sensitive: bool) bool {
    if (needle.len > haystack.len) return false;
    return equals(haystack[0..needle.len], needle, case_sensitive);
}

fn compareRankedLine(_: void, left: RankedLine, right: RankedLine) bool {
    const left_total = left.score.total();
    const right_total = right.score.total();
    if (left_total == right_total) return std.mem.lessThan(u8, left.text, right.text);
    return left_total > right_total;
}
