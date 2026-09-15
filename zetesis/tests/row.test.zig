const std = @import("std");
const row = @import("zetesis").row;

test "right side layout without score reserves git marker" {
    const layout = row.rightSideLayout(12, null);
    try std.testing.expectEqual(@as(u16, 9), layout.text_end);
    try std.testing.expectEqual(@as(?u16, 11), layout.git_col);
    try std.testing.expectEqual(@as(?u16, null), layout.score_start);
}

test "right side layout with score reserves status and score" {
    const layout = row.rightSideLayout(12, 2);
    try std.testing.expectEqual(@as(u16, 7), layout.text_end);
    try std.testing.expectEqual(@as(?u16, 8), layout.git_col);
    try std.testing.expectEqual(@as(?u16, 10), layout.score_start);
}

test "right side layout skips right side when too narrow" {
    const no_score = row.rightSideLayout(4, null);
    try std.testing.expectEqual(@as(u16, 4), no_score.text_end);
    try std.testing.expectEqual(@as(?u16, null), no_score.git_col);

    const score = row.rightSideLayout(6, 2);
    try std.testing.expectEqual(@as(u16, 6), score.text_end);
    try std.testing.expectEqual(@as(?u16, null), score.git_col);
    try std.testing.expectEqual(@as(?u16, null), score.score_start);
}
