const std = @import("std");

const Action = @import("actions.zig").Action;

pub fn formatActionResult(allocator: std.mem.Allocator, action: Action, paths: []const []const u8) ![]const u8 {
    var result: std.Io.Writer.Allocating = .init(allocator);
    errdefer result.deinit();

    for (paths) |path| {
        try writeFileSelection(&result.writer, action, path);
        try result.writer.writeByte('\n');
    }

    return result.toOwnedSlice();
}

fn writeFileSelection(writer: *std.Io.Writer, action: Action, path: []const u8) !void {
    var json: std.json.Stringify = .{ .writer = writer };
    try json.beginObject();
    try json.objectField("action");
    try json.write(action.label());
    try json.objectField("kind");
    try json.write("file");
    try json.objectField("path");
    try json.write(path);
    try json.endObject();
}

test "formatActionResult writes file selection jsonl" {
    const result = try formatActionResult(std.testing.allocator, .vsplit, &.{"src/main.zig"});
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("{\"action\":\"vsplit\",\"kind\":\"file\",\"path\":\"src/main.zig\"}\n", result);
}

test "formatActionResult writes quickfix jsonl entries" {
    const result = try formatActionResult(std.testing.allocator, .quickfix, &.{ "a.zig", "b.zig" });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("{\"action\":\"quickfix\",\"kind\":\"file\",\"path\":\"a.zig\"}\n{\"action\":\"quickfix\",\"kind\":\"file\",\"path\":\"b.zig\"}\n", result);
}
