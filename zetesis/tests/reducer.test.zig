const std = @import("std");
const reducer = @import("zetesis").reducer;

test "escape quits files but returns from help" {
    try std.testing.expectEqual(reducer.Effect.quit, reducer.reduce(.files, .back));
    try std.testing.expectEqual(reducer.Effect.switch_files, reducer.reduce(.help, .back));
}

test "help key only switches from files" {
    try std.testing.expectEqual(reducer.Effect.switch_help, reducer.reduce(.files, .help));
    try std.testing.expectEqual(reducer.Effect.none, reducer.reduce(.help, .help));
}

test "file-only actions stay out of help search" {
    try std.testing.expectEqual(reducer.Effect.mark, reducer.reduce(.files, .mark));
    try std.testing.expectEqual(reducer.Effect.none, reducer.reduce(.help, .mark));
}
