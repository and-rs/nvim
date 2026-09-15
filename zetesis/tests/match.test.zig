const std = @import("std");
const match = @import("zetesis").match;

test "generic fuzzy matching prefers contiguous boundary matches" {
    const contiguous = match.fuzzy.score("src/main.zig", "mai", false).?;
    const scattered = match.fuzzy.score("src/model/api/index.zig", "mai", false).?;
    try std.testing.expect(contiguous > scattered);
}

test "path matching prefers the filename" {
    const filename = match.path.score("src/main.zig", "main", .{}).?;
    const directory = match.path.score("main/generated/index.zig", "main", .{}).?;
    try std.testing.expect(filename > directory);
}

test "path matches highlight the selected filename" {
    var result = (try match.path.match(std.testing.allocator, "src/main.zig", "main", .{})).?;
    defer match.fuzzy.deinit(&result, std.testing.allocator);
    try std.testing.expectEqualSlices(usize, &.{ 4, 5, 6, 7 }, result.indexes);
}
