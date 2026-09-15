const vaxis = @import("vaxis");

pub const Mode = enum { files, help };

pub const Command = enum {
    none,
    quit,
    back,
    open,
    mark,
    vsplit,
    tabedit,
    help,
    down,
    up,
};

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

pub const Special = enum {
    none,
    escape,
    enter,
    down,
    up,
    f1,
};

pub const Input = struct {
    byte: ?u8 = null,
    ctrl: bool = false,
    special: Special = .none,
};

pub fn decodeInput(input: Input) Command {
    return switch (input.special) {
        .escape => .back,
        .enter => .open,
        .down => .down,
        .up => .up,
        .f1 => .help,
        .none => decodeByte(input.byte, input.ctrl),
    };
}

pub fn decodeKey(key: vaxis.Key) Command {
    if (key.matches(vaxis.Key.escape, .{})) return .back;
    if (key.matches(vaxis.Key.enter, .{})) return .open;
    if (key.matches(vaxis.Key.down, .{})) return .down;
    if (key.matches(vaxis.Key.up, .{})) return .up;
    if (key.matches(vaxis.Key.f1, .{})) return .help;
    if (key.matches('c', .{ .ctrl = true })) return .quit;
    if (key.matches('y', .{ .ctrl = true })) return .mark;
    if (key.matches('v', .{ .ctrl = true })) return .vsplit;
    if (key.matches('t', .{ .ctrl = true })) return .tabedit;
    if (key.matches('g', .{ .ctrl = true })) return .help;
    if (key.matches('n', .{ .ctrl = true })) return .down;
    if (key.matches('p', .{ .ctrl = true })) return .up;
    return .none;
}

pub fn reduce(mode: Mode, command: Command) Effect {
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

fn decodeByte(byte: ?u8, ctrl: bool) Command {
    const value = byte orelse return .none;
    if (!ctrl) return .none;
    return switch (value) {
        'c' => .quit,
        'y' => .mark,
        'v' => .vsplit,
        't' => .tabedit,
        'g' => .help,
        'n' => .down,
        'p' => .up,
        else => .none,
    };
}
