const std = @import("std");
const vaxis = @import("vaxis");

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
    if (key.matches(';', .{ .ctrl = true })) return .help;
    if (key.matches('j', .{}) or key.matches('n', .{ .ctrl = true })) return .down;
    if (key.matches('k', .{}) or key.matches('p', .{ .ctrl = true })) return .up;
    return .none;
}

fn decodeByte(byte: ?u8, ctrl: bool) Command {
    const value = byte orelse return .none;
    if (ctrl) {
        return switch (value) {
            'c' => .quit,
            'y' => .mark,
            'v' => .vsplit,
            't' => .tabedit,
            ';' => .help,
            'n' => .down,
            'p' => .up,
            else => .none,
        };
    }

    return switch (value) {
        'j' => .down,
        'k' => .up,
        else => .none,
    };
}

test "ctrl semicolon opens help" {
    try std.testing.expectEqual(Command.help, decodeInput(.{ .byte = ';', .ctrl = true }));
}

test "f1 opens help" {
    try std.testing.expectEqual(Command.help, decodeInput(.{ .special = .f1 }));
}

test "ctrl g is not a picker command" {
    try std.testing.expectEqual(Command.none, decodeInput(.{ .byte = 'g', .ctrl = true }));
}

test "question mark is not help" {
    try std.testing.expectEqual(Command.none, decodeInput(.{ .byte = '?' }));
}