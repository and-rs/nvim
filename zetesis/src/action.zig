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
