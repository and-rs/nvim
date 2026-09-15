const std = @import("std");
const discover = @import("zetesis").discover;
const GitStatus = @import("zetesis").git.GitStatus;

test "fd lists files and skips gitignored paths" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "keep.txt", .data = "keep\n" });
    try tmp.dir.createDir(io, "node_modules", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "node_modules/pkg.js", .data = "x\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = ".gitignore", .data = "node_modules\n.env\n.env.*\nsecret.txt\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "secret.txt", .data = "nope\n" });
    try gitInit(tmp.dir);

    var index = try collectOrSkip(tmp.dir);
    defer index.deinit();

    try std.testing.expect(index.contains("keep.txt"));
    try std.testing.expect(index.contains(".gitignore"));
    try std.testing.expect(!index.contains("secret.txt"));
    try std.testing.expect(!index.contains("node_modules/pkg.js"));
}

test "gitignored env files are still listed" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "keep.txt", .data = "keep\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = ".gitignore", .data = ".env\n.env.*\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = ".env", .data = "SECRET=1\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = ".env.local", .data = "SECRET=2\n" });
    try tmp.dir.createDir(io, "apps", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "apps/.env.production", .data = "SECRET=3\n" });
    try gitInit(tmp.dir);

    var index = try collectOrSkip(tmp.dir);
    defer index.deinit();

    try std.testing.expect(index.contains("keep.txt"));
    try std.testing.expect(index.contains(".env"));
    try std.testing.expect(index.contains(".env.local"));
    try std.testing.expect(index.contains("apps/.env.production"));
}

test "git status overlays untracked files" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "keep.txt", .data = "keep\n" });
    try gitInit(tmp.dir);

    var index = try collectOrSkip(tmp.dir);
    defer index.deinit();

    try std.testing.expectEqual(GitStatus.untracked, index.statusOf("keep.txt").?);
}

test "pump drains until done" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "a.txt", .data = "a\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "b.txt", .data = "b\n" });
    try gitInit(tmp.dir);

    var d: discover.Discover = undefined;
    d.start(std.testing.allocator, io, .{ .dir = tmp.dir }) catch |err| switch (err) {
        error.FdMissing => return error.SkipZigTest,
        else => |e| return e,
    };
    defer d.deinit();

    var index = discover.Index.init(std.testing.allocator);
    defer index.deinit();

    var steps: usize = 0;
    while (try d.pump(&index) == .more) {
        steps += 1;
        if (steps > 10_000) return error.TestUnexpectedResult;
        try io.sleep(.fromMilliseconds(1), .real);
    }
    try std.testing.expect(index.contains("a.txt"));
    try std.testing.expect(index.contains("b.txt"));
}

test "static indexes retain duplicate input" {
    var index = discover.Index.init(std.testing.allocator);
    defer index.deinit();
    try index.append("same");
    try index.append("same");
    try std.testing.expectEqual(@as(usize, 2), index.items.items.len);
}

fn collectOrSkip(dir: std.Io.Dir) !discover.Index {
    return discover.collect(std.testing.allocator, std.testing.io, .{ .dir = dir }) catch |err| switch (err) {
        error.FdMissing => return error.SkipZigTest,
        else => |e| return e,
    };
}

fn gitInit(dir: std.Io.Dir) !void {
    const io = std.testing.io;
    const result = try std.process.run(std.testing.allocator, io, .{
        .argv = &.{ "git", "init" },
        .cwd = .{ .dir = dir },
    });
    defer {
        std.testing.allocator.free(result.stdout);
        std.testing.allocator.free(result.stderr);
    }
    try std.testing.expectEqual(@as(u8, 0), result.term.exited);
}
