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

test "git file collection skips deleted tracked files" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "keep.txt", .data = "keep\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "gone.txt", .data = "gone\n" });
    try tmp.dir.createDir(io, "nested", .default_dir);

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
        .argv = &.{ "git", "add", "keep.txt", "gone.txt", "nested" },
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
        .argv = &.{ "git", "ls-files", "-z", "--cached", "--others", "--exclude-standard" },
        .cwd = .{ .dir = tmp.dir },
    });
    defer {
        std.testing.allocator.free(git_result.stdout);
        std.testing.allocator.free(git_result.stderr);
    }

    const git_lines = try git.collectNulDelimitedLines(std.testing.allocator, git_result.stdout);
    var dir = try std.Io.Dir.openDir(tmp.dir, io, ".", .{ .iterate = true });
    defer dir.close(io);

    const lines = try git.filterExistingFiles(std.testing.allocator, io, dir, git_lines);
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
