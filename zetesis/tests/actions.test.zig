const std = @import("std");
const actions = @import("zetesis").actions;

test "help lines mirror help entries" {
    try std.testing.expectEqual(actions.help_entries.len, actions.help_lines.len);
    for (actions.help_entries, 0..) |entry, index| {
        try std.testing.expectEqualStrings(entry.text, actions.help_lines[index]);
    }
}

test "help actions dispatch to shared picker actions" {
    try std.testing.expectEqual(actions.HelpDispatch{ .file_action = .edit }, actions.dispatchForHelpAction(.open));
    try std.testing.expectEqual(actions.HelpDispatch{ .file_action = .vsplit }, actions.dispatchForHelpAction(.vsplit));
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

test "help entry lookup handles empty results" {
    try std.testing.expectEqual(null, actions.helpEntryAt(&.{}, 0));
    try std.testing.expectEqual(null, actions.helpEntryAt(&.{"missing"}, 0));
    const entry = actions.helpEntryAt(actions.help_lines[0..], 0) orelse return error.MissingHelpEntry;
    try std.testing.expectEqual(actions.HelpAction.open, entry.action);
}
