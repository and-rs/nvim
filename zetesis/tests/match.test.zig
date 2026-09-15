const std = @import("std");
const matcher = @import("zetesis").matcher;

test "query prefixes filter and highlight paths" {
    const terms = try matcher.parseQuery(std.testing.allocator, ">config #nu %nushell");
    defer std.testing.allocator.free(terms);
    const ranked = try matcher.rankQueryTop(std.testing.allocator, &.{ "common/nushell/config.nu", "config/nushell.txt", "common/nushell/other.nu" }, terms, .{}, 10);
    defer {
        for (ranked) |line| std.testing.allocator.free(line.match_indexes);
        std.testing.allocator.free(ranked);
    }
    try std.testing.expectEqual(@as(usize, 1), ranked.len);
    try std.testing.expectEqualStrings("common/nushell/config.nu", ranked[0].text);
    try std.testing.expect(std.mem.indexOfScalar(usize, ranked[0].match_indexes, 7) != null);
}

test "empty query prefixes remain fuzzy text" {
    const terms = try matcher.parseQuery(std.testing.allocator, "% > #");
    defer std.testing.allocator.free(terms);
    try std.testing.expectEqual(@as(usize, 3), terms.len);
    for (terms) |term| try std.testing.expect(std.meta.activeTag(term) == .fuzzy);
}

test "literal smart case and basename exclusion" {
    const literal = try matcher.parseQuery(std.testing.allocator, "%Bar.qml");
    defer std.testing.allocator.free(literal);
    try std.testing.expect(matcher.rankQuery("src/Bar.qml", literal, .{}) != null);
    try std.testing.expect(matcher.rankQuery("src/bar.qml", literal, .{}) == null);

    const basename = try matcher.parseQuery(std.testing.allocator, ">config");
    defer std.testing.allocator.free(basename);
    try std.testing.expect(matcher.rankQuery("config/file.nu", basename, .{}) == null);
}

test "filename priority" {
    const needles = &.{"make"};
    const direct = (matcher.rank("GNUmakefile", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    const nested = (matcher.rank("source/blender/makesdna/DNA_genfile.h", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    try std.testing.expect(direct > nested);
}

test "matching parent directory beats unrelated path subsequence" {
    const needles = &.{"nushell"};
    const directory_match = (matcher.rank("common/nushell/config.nu", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    const unrelated = (matcher.rank("nixos/quickshell/AGENTS.md", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    try std.testing.expect(directory_match > unrelated);
}

test "nearest exact component order beats nested and filename substring matches" {
    const needles = &.{"bar"};
    const filename = (matcher.rank("nixos/quickshell/Bar/Bar.qml", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    const direct_parent = (matcher.rank("nixos/quickshell/Bar/Config.qml", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    const nested = (matcher.rank("nixos/quickshell/Bar/Status/Battery/Button.qml", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    const filename_substring = (matcher.rank("nixos/quickshell/NotificationV2/NotificationTimeoutBar.qml", needles, .{}) orelse matcher.ScoreBreakdown{}).total();

    try std.testing.expect(filename > direct_parent);
    try std.testing.expect(direct_parent > nested);
    try std.testing.expect(nested > filename_substring);
}

test "component match indexes follow the ranked directory component" {
    const indexes = try matcher.matchIndexes(std.testing.allocator, "common/nushell/config.nu", &.{"nushell"}, false);
    defer std.testing.allocator.free(indexes);

    try std.testing.expectEqualSlices(usize, &.{ 7, 8, 9, 10, 11, 12, 13 }, indexes);
}

test "exact filename highlights the filename component" {
    const indexes = try matcher.matchIndexes(std.testing.allocator, "nixos/quickshell/Bar/Bar.qml", &.{"bar"}, false);
    defer std.testing.allocator.free(indexes);

    try std.testing.expectEqualSlices(usize, &.{ 21, 22, 23 }, indexes);
}

test "contiguous filename match beats separated filename match" {
    const needles = &.{"mu"};
    const contiguous = (matcher.rank("lua/plugins/tmux.lua", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    const separated = (matcher.rank("lua/config/map.lua", needles, .{}) orelse matcher.ScoreBreakdown{}).total();
    try std.testing.expect(contiguous > separated);
}

test "strict path" {
    const needles = &.{"a/m/f/b/baz"};
    try std.testing.expect(matcher.rank("app/models/foo/bar/baz.rb", needles, .{}) != null);
    try std.testing.expect(matcher.rank("app/monsters/dungeon/foo/bar/baz.rb", needles, .{}) == null);
}

test "score breakdown keeps filename and exact boosts visible" {
    const ranked = matcher.rank("src/main.zig", &.{"main.zig"}, .{}) orelse return error.TestUnexpectedResult;
    try std.testing.expect(ranked.fuzzy > 0);
    try std.testing.expect(ranked.filename_boost > 0);
    try std.testing.expect(ranked.exact_filename_boost > 0);
    try std.testing.expect(ranked.total() > ranked.fuzzy);
}

test "current file penalty lowers total only" {
    const ranked = matcher.rank("src/main.zig", &.{"main"}, .{ .current_file = "src/main.zig" }) orelse return error.TestUnexpectedResult;
    try std.testing.expect(ranked.fuzzy > 0);
    try std.testing.expect(ranked.current_file_penalty < 0);
}

test "ranked lines keep source index and match positions" {
    const ranked = try matcher.rankAll(std.testing.allocator, &.{ "src/main.zig", "README.md" }, &.{"main"}, .{});
    defer {
        for (ranked) |line| std.testing.allocator.free(line.match_indexes);
        std.testing.allocator.free(ranked);
    }

    try std.testing.expectEqual(@as(usize, 0), ranked[0].source_index);
    try std.testing.expectEqual(@as(usize, 4), ranked[0].match_indexes.len);
    try std.testing.expectEqual(@as(usize, 4), ranked[0].match_indexes[0]);
}

test "rankTop keeps only best matches" {
    const ranked = try matcher.rankTop(std.testing.allocator, &.{ "src/main.zig", "src/matcher.zig", "README.md" }, &.{"zig"}, .{}, 1);
    defer {
        for (ranked) |line| std.testing.allocator.free(line.match_indexes);
        std.testing.allocator.free(ranked);
    }

    try std.testing.expectEqual(@as(usize, 1), ranked.len);
    try std.testing.expect(ranked[0].match_indexes.len > 0);
}
