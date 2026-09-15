const std = @import("std");
const git = @import("zetesis").git;

test "NUL-delimited file list drops blanks and duplicates text" {
    const lines = try git.collectNulDelimitedLines(std.testing.allocator, "a.zig\x00\x00b.zig\x00");
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
    try std.testing.expectEqual(git.GitStatus.modified, try git.gitStatusForPath(std.testing.allocator, output, "src/main.zig"));
    try std.testing.expectEqual(git.GitStatus.added, try git.gitStatusForPath(std.testing.allocator, output, "src/new.zig"));
    try std.testing.expectEqual(git.GitStatus.untracked, try git.gitStatusForPath(std.testing.allocator, output, "scratch.txt"));
    try std.testing.expectEqual(git.GitStatus.renamed, try git.gitStatusForPath(std.testing.allocator, output, "new.txt"));
    try std.testing.expectEqual(git.GitStatus.none, try git.gitStatusForPath(std.testing.allocator, output, "old.txt"));
}

test "NUL-delimited file list preserves newlines in paths" {
    const lines = try git.collectNulDelimitedLines(std.testing.allocator, "normal.zig\x00line\nbreak.zig\x00");
    defer {
        for (lines) |line| std.testing.allocator.free(line);
        std.testing.allocator.free(lines);
    }

    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("line\nbreak.zig", lines[1]);
}
