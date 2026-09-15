const std = @import("std");
const protocol = @import("zetesis").protocol;

test "formatResults writes file jsonl entries" {
    const result = try protocol.formatResults(std.testing.allocator, &.{
        .{ .action = .quickfix, .output = .{ .file = .{ .path = "a.zig" } } },
        .{ .action = .quickfix, .output = .{ .file = .{ .path = "b.zig" } } },
    });
    defer std.testing.allocator.free(result);
    try std.testing.expectEqualStrings("{\"action\":\"quickfix\",\"kind\":\"file\",\"path\":\"a.zig\"}\n{\"action\":\"quickfix\",\"kind\":\"file\",\"path\":\"b.zig\"}\n", result);
}

test "formatResults writes location and text jsonl" {
    const result = try protocol.formatResults(std.testing.allocator, &.{
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
