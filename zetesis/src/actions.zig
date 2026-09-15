const std = @import("std");
const fuzzy = @import("match/fuzzy.zig");

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

pub const RankedHelp = struct {
    index: usize,
    score: i32,
};

pub fn rankHelp(query: []const u8, out: []RankedHelp) usize {
    var count: usize = 0;
    const case_sensitive = fuzzy.hasUpper(query);
    for (help_entries, 0..) |entry, index| {
        const score = fuzzy.score(entry.text, query, case_sensitive) orelse continue;
        if (count < out.len) out[count] = .{ .index = index, .score = score };
        count += 1;
    }
    const used = @min(count, out.len);
    std.mem.sort(RankedHelp, out[0..used], {}, rankedBefore);
    return used;
}

pub fn helpEntryAt(ranked: []const RankedHelp, cursor: usize) ?HelpEntry {
    if (cursor >= ranked.len) return null;
    return help_entries[ranked[cursor].index];
}

fn rankedBefore(_: void, left: RankedHelp, right: RankedHelp) bool {
    if (left.score != right.score) return left.score > right.score;
    return left.index < right.index;
}
