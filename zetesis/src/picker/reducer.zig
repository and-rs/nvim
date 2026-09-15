const std = @import("std");

const key_decoder = @import("key_decoder.zig");
const state = @import("state.zig");

pub const Effect = enum {
    none,
    quit,
    switch_files,
    switch_help,
    open,
    mark,
    vsplit,
    tabedit,
    move_down,
    move_up,
};

pub fn reduce(mode: state.Mode, command: key_decoder.Command) Effect {
    return switch (command) {
        .none => .none,
        .quit => .quit,
        .back => switch (mode) {
            .files => .quit,
            .help => .switch_files,
        },
        .help => switch (mode) {
            .files => .switch_help,
            .help => .none,
        },
        .open => .open,
        .mark => switch (mode) {
            .files => .mark,
            .help => .none,
        },
        .vsplit => switch (mode) {
            .files => .vsplit,
            .help => .none,
        },
        .tabedit => switch (mode) {
            .files => .tabedit,
            .help => .none,
        },
        .down => .move_down,
        .up => .move_up,
    };
}
