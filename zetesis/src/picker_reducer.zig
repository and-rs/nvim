const std = @import("std");

const key_decoder = @import("key_decoder.zig");
const picker_state = @import("picker_state.zig");

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

pub fn reduce(mode: picker_state.Mode, command: key_decoder.Command) Effect {
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

test "escape quits files but returns from help" {
    try std.testing.expectEqual(Effect.quit, reduce(.files, .back));
    try std.testing.expectEqual(Effect.switch_files, reduce(.help, .back));
}

test "help key only switches from files" {
    try std.testing.expectEqual(Effect.switch_help, reduce(.files, .help));
    try std.testing.expectEqual(Effect.none, reduce(.help, .help));
}

test "file-only actions stay out of help search" {
    try std.testing.expectEqual(Effect.mark, reduce(.files, .mark));
    try std.testing.expectEqual(Effect.none, reduce(.help, .mark));
}
