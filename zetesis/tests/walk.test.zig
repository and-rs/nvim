const std = @import("std");
const walk = @import("zetesis").walk;

test "walk files falls back and skips dot git" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.createDir(io, "src", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "src/main.zig", .data = "" });
    try tmp.dir.writeFile(io, .{ .sub_path = "README.md", .data = "" });
    try tmp.dir.createDir(io, ".git", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = ".git/config", .data = "" });
    try tmp.dir.createDir(io, "node_modules", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = "node_modules/package.js", .data = "" });
    try tmp.dir.createDir(io, ".zig-cache", .default_dir);
    try tmp.dir.writeFile(io, .{ .sub_path = ".zig-cache/cache.bin", .data = "" });

    var dir = try std.Io.Dir.openDir(tmp.dir, io, ".", .{ .iterate = true });
    defer dir.close(io);

    const lines = try walk.collect(std.testing.allocator, io, dir);
    defer {
        for (lines) |line| std.testing.allocator.free(line);
        std.testing.allocator.free(lines);
    }

    try std.testing.expectEqual(@as(usize, 2), lines.len);
    try std.testing.expectEqualStrings("README.md", lines[0]);
    try std.testing.expectEqualStrings("src/main.zig", lines[1]);
}
