const std = @import("std");
const actions = @import("zetesis").actions;

test "help lines are unique and dispatch to picker actions" {
    try std.testing.expectEqual(actions.HelpDispatch{ .file_action = .edit }, actions.dispatchForHelpAction(.open));
    try std.testing.expectEqual(actions.HelpDispatch{ .file_action = .vsplit }, actions.dispatchForHelpAction(.vsplit));
    try std.testing.expectEqual(actions.HelpDispatch{ .file_action = .tabedit }, actions.dispatchForHelpAction(.tabedit));
    try std.testing.expectEqual(actions.HelpDispatch.mark, actions.dispatchForHelpAction(.mark));
    try std.testing.expectEqual(actions.HelpDispatch.back, actions.dispatchForHelpAction(.back));
    try std.testing.expectEqual(actions.HelpDispatch.quit, actions.dispatchForHelpAction(.quit));
}

test "action label parser matches labels" {
    try std.testing.expectEqual(actions.Action.edit, actions.Action.parse("edit").?);
    try std.testing.expectEqual(actions.Action.vsplit, actions.Action.parse("vsplit").?);
    try std.testing.expectEqual(actions.Action.tabedit, actions.Action.parse("tabedit").?);
    try std.testing.expectEqual(actions.Action.quickfix, actions.Action.parse("quickfix").?);
    try std.testing.expectEqual(null, actions.Action.parse("bogus"));
}

test "empty help query ranks every entry in order" {
    var ranked: [actions.help_entries.len]actions.RankedHelp = undefined;
    const count = actions.rankHelp("", ranked[0..]);
    try std.testing.expectEqual(actions.help_entries.len, count);
    for (0..count) |index| try std.testing.expectEqual(index, ranked[index].index);
}

test "help query filters to matching actions" {
    var ranked: [actions.help_entries.len]actions.RankedHelp = undefined;
    const count = actions.rankHelp("split", ranked[0..]);
    try std.testing.expectEqual(@as(usize, 1), count);
    try std.testing.expectEqual(actions.HelpAction.vsplit, actions.help_entries[ranked[0].index].action);
}

test "help entry lookup handles empty results" {
    try std.testing.expectEqual(null, actions.helpEntryAt(&.{}, 0));
    var ranked: [actions.help_entries.len]actions.RankedHelp = undefined;
    const count = actions.rankHelp("", ranked[0..]);
    const entry = actions.helpEntryAt(ranked[0..count], 0) orelse return error.MissingHelpEntry;
    try std.testing.expectEqual(actions.HelpAction.open, entry.action);
}
