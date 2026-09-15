const std = @import("std");
const fields = @import("zetesis").fields;

test "projects selected fields" {
    const output = try fields.project(std.testing.allocator, "path\tlabel\tpayload", "\t", "2,3");
    defer std.testing.allocator.free(output);
    try std.testing.expectEqualStrings("label\tpayload", output);
}

test "projects field ranges" {
    const output = try fields.project(std.testing.allocator, "a\tb\tc", "\t", "2..");
    defer std.testing.allocator.free(output);
    try std.testing.expectEqualStrings("b\tc", output);
}
