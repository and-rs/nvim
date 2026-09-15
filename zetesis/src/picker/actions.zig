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

    pub fn parse(name: []const u8) ?Action {
        if (std.mem.eql(u8, name, "edit")) return .edit;
        if (std.mem.eql(u8, name, "vsplit")) return .vsplit;
        if (std.mem.eql(u8, name, "tabedit")) return .tabedit;
        if (std.mem.eql(u8, name, "quickfix")) return .quickfix;
        return null;
    }
};

pub const HelpAction = enum {
    open,
    mark,
    vsplit,
    tabedit,
    quit,
    back,
    info,
};

pub const HelpEntry = struct {
    text: []const u8,
    action: HelpAction,
};

pub const HelpDispatch = union(enum) {
    back,
    quit,
    mark,
    none,
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
        .info => .none,
    };
}

pub const help_entries = [_]HelpEntry{
    .{ .text = "Open current selection   Enter", .action = .open },
    .{ .text = "Mark or unmark row       Ctrl-y", .action = .mark },
    .{ .text = "Open in vertical split   Ctrl-v", .action = .vsplit },
    .{ .text = "Open in new tab          Ctrl-t", .action = .tabedit },
    .{ .text = "Fuzzy path term          name", .action = .info },
    .{ .text = "Literal path substring   %literal", .action = .info },
    .{ .text = "Filename-only fuzzy      >name", .action = .info },
    .{ .text = "Extension suffix filter  #zig / #test.ts", .action = .info },
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
