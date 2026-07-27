const std = @import("std");

const Action = @import("actions.zig").Action;
const candidates = @import("../candidates.zig");

pub const ResultEntry = struct {
    action: Action,
    output: candidates.Output,
};

pub fn formatActionResult(allocator: std.mem.Allocator, action: Action, paths: []const []const u8) ![]const u8 {
    var result: std.Io.Writer.Allocating = .init(allocator);
    errdefer result.deinit();

    for (paths) |path| {
        try writeFileSelection(&result.writer, action, path);
        try result.writer.writeByte('\n');
    }

    return result.toOwnedSlice();
}

pub fn formatResults(allocator: std.mem.Allocator, entries: []const ResultEntry) ![]const u8 {
    var result: std.Io.Writer.Allocating = .init(allocator);
    errdefer result.deinit();

    for (entries) |entry| {
        try writeResult(&result.writer, entry);
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

fn writeResult(writer: *std.Io.Writer, entry: ResultEntry) !void {
    var json: std.json.Stringify = .{ .writer = writer };
    try json.beginObject();
    try json.objectField("action");
    try json.write(entry.action.label());

    switch (entry.output) {
        .file => |file| {
            try json.objectField("kind");
            try json.write("file");
            try json.objectField("path");
            try json.write(file.path);
        },
        .location => |location| {
            try json.objectField("kind");
            try json.write("location");
            try json.objectField("path");
            try json.write(location.path);
            try json.objectField("line");
            try json.write(location.line);
            try json.objectField("col");
            try json.write(location.col);
            try json.objectField("text");
            try json.write(location.text);
        },
        .text => |text| {
            try json.objectField("kind");
            try json.write("text");
            try json.objectField("text");
            try json.write(text.text);
        },
    }

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

test "formatResults writes location and text jsonl" {
    const result = try formatResults(std.testing.allocator, &.{
        .{ .action = .edit, .output = .{ .location = .{ .path = "src/main.zig", .line = 10, .col = 5, .text = "main" } } },
        .{ .action = .quickfix, .output = .{ .text = .{ .text = "hello" } } },
    });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings(
        "{\"action\":\"edit\",\"kind\":\"location\",\"path\":\"src/main.zig\",\"line\":10,\"col\":5,\"text\":\"main\"}\n" ++
            "{\"action\":\"quickfix\",\"kind\":\"text\",\"text\":\"hello\"}\n",
        result,
    );
}
