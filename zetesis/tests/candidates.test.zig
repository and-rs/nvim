const std = @import("std");
const candidates = @import("zetesis").candidates;

test "parse minimal file candidate" {
    const parsed = try candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"file\",\"path\":\"src/main.zig\"}\n");
    defer candidates.deinitCandidates(std.testing.allocator, parsed);

    try std.testing.expectEqual(@as(usize, 1), parsed.len);
    try std.testing.expectEqualStrings("src/main.zig", parsed[0].match_text);
    try std.testing.expectEqualStrings("src/main.zig", parsed[0].display_text);
    try std.testing.expectEqualStrings("src/main.zig", parsed[0].output.file.path);
}

test "parse location candidate" {
    const parsed = try candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"location\",\"path\":\"src/main.zig\",\"line\":10,\"col\":5,\"text\":\"main\"}\n");
    defer candidates.deinitCandidates(std.testing.allocator, parsed);

    try std.testing.expectEqual(@as(usize, 1), parsed.len);
    try std.testing.expectEqualStrings("main", parsed[0].match_text);
    try std.testing.expectEqualStrings("main", parsed[0].display_text);
    try std.testing.expectEqualStrings("src/main.zig", parsed[0].output.location.path);
    try std.testing.expectEqual(@as(usize, 10), parsed[0].output.location.line);
    try std.testing.expectEqual(@as(usize, 5), parsed[0].output.location.col);
}

test "parse text candidate" {
    const parsed = try candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"text\",\"text\":\"hello\"}\n");
    defer candidates.deinitCandidates(std.testing.allocator, parsed);

    try std.testing.expectEqual(@as(usize, 1), parsed.len);
    try std.testing.expectEqualStrings("hello", parsed[0].match_text);
    try std.testing.expectEqualStrings("hello", parsed[0].display_text);
    try std.testing.expectEqualStrings("hello", parsed[0].output.text.text);
}

test "match and display fallback rules" {
    const parsed = try candidates.parseJsonl(
        std.testing.allocator,
        "{\"kind\":\"file\",\"path\":\"src/main.zig\",\"display\":\"main file\",\"match\":\"main\",\"action\":\"vsplit\"}\n" ++
            "{\"kind\":\"text\",\"display\":\"Shown\",\"match\":\"Find me\"}\n",
    );
    defer candidates.deinitCandidates(std.testing.allocator, parsed);

    try std.testing.expectEqualStrings("main", parsed[0].match_text);
    try std.testing.expectEqualStrings("main file", parsed[0].display_text);
    try std.testing.expectEqualStrings("vsplit", parsed[0].default_action.?);

    try std.testing.expectEqualStrings("Find me", parsed[1].match_text);
    try std.testing.expectEqualStrings("Shown", parsed[1].display_text);
    try std.testing.expectEqualStrings("Shown", parsed[1].output.text.text);
}

test "invalid action returns error" {
    try std.testing.expectError(error.InvalidAction, candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"file\",\"path\":\"src/main.zig\",\"action\":\"bogus\"}\n"));
}

test "parse malformed json returns error" {
    try std.testing.expectError(error.InvalidJson, candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"file\"\n"));
}

test "missing required field returns error" {
    try std.testing.expectError(error.MissingPath, candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"file\"}\n"));
}

test "unknown kind returns error" {
    try std.testing.expectError(error.UnknownKind, candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"whatever\",\"text\":\"x\"}\n"));
}

test "invalid field type returns error" {
    try std.testing.expectError(error.InvalidFieldType, candidates.parseJsonl(std.testing.allocator, "{\"kind\":\"location\",\"path\":\"src/main.zig\",\"line\":\"ten\"}\n"));
}
