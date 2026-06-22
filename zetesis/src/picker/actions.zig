const std = @import("std");

pub const Action = enum {
    edit,
    vsplit,
    tabedit,
    quickfix,

    pub fn label(self: Action) []const u8 {
        return switch (self) {
            .edit => "edit",
            .vsplit => "vsplit",
            .tabedit => "tabedit",
            .quickfix => "quickfix",
        };
    }
};

pub const HelpAction = enum {
    open,
    mark,
    vsplit,
    tabedit,
    quit,
    back,
};

pub const HelpEntry = struct {
    text: []const u8,
    action: HelpAction,
};

pub const HelpDispatch = union(enum) {
    back,
    quit,
    mark,
    file_action: Action,
};

pub fn dispatchForHelpAction(action: HelpAction) HelpDispatch {
    return switch (action) {
        .open => .{ .file_action = .edit },
        .mark => .mark,
        .vsplit => .{ .file_action = .vsplit },
        .tabedit => .{ .file_action = .tabedit },
        .quit => .quit,
        .back => .back,
    };
}

pub const help_entries = [_]HelpEntry{
    .{ .text = "Open current selection   Enter", .action = .open },
    .{ .text = "Mark or unmark row       Ctrl-y", .action = .mark },
    .{ .text = "Open in vertical split   Ctrl-v", .action = .vsplit },
    .{ .text = "Open in new tab          Ctrl-t", .action = .tabedit },
    .{ .text = "Return to file picker    Esc", .action = .back },
    .{ .text = "Quit zetesis             Esc / Ctrl-c", .action = .quit },
};

pub const help_lines = blk: {
    var lines: [help_entries.len][]const u8 = undefined;
    for (help_entries, 0..) |entry, index| {
        lines[index] = entry.text;
    }
    break :blk lines;
};

pub fn helpEntryForText(text: []const u8) ?HelpEntry {
    for (help_entries) |entry| {
        if (std.mem.eql(u8, entry.text, text)) return entry;
    }
    return null;
}

pub fn helpEntryAt(lines: []const []const u8, cursor: usize) ?HelpEntry {
    if (cursor >= lines.len) return null;
    return helpEntryForText(lines[cursor]);
}

test "help lines mirror help entries" {
    try std.testing.expectEqual(help_entries.len, help_lines.len);
    for (help_entries, 0..) |entry, index| {
        try std.testing.expectEqualStrings(entry.text, help_lines[index]);
    }
}

test "help actions dispatch to shared picker actions" {
    try std.testing.expectEqual(HelpDispatch{ .file_action = .edit }, dispatchForHelpAction(.open));
    try std.testing.expectEqual(HelpDispatch{ .file_action = .vsplit }, dispatchForHelpAction(.vsplit));
    try std.testing.expectEqual(HelpDispatch.mark, dispatchForHelpAction(.mark));
    try std.testing.expectEqual(HelpDispatch.back, dispatchForHelpAction(.back));
    try std.testing.expectEqual(HelpDispatch.quit, dispatchForHelpAction(.quit));
}

test "help entry lookup handles empty results" {
    try std.testing.expectEqual(null, helpEntryAt(&.{}, 0));
    try std.testing.expectEqual(null, helpEntryAt(&.{"missing"}, 0));
    const entry = helpEntryAt(help_lines[0..], 0) orelse return error.MissingHelpEntry;
    try std.testing.expectEqual(HelpAction.open, entry.action);
}
