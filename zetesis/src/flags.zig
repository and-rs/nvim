const std = @import("std");

pub const Mode = enum {
    stdin,
    files,
    candidates,
};

pub const Config = struct {
    mode: Mode,
    filter: ?[]const u8 = null,
    cwd: ?[]const u8 = null,
    current_file: ?[]const u8 = null,
    output_file: ?[]const u8 = null,
    plain: bool = false,
    show_scores: bool = true,
    debug_scores: bool = false,
};

const Flag = enum {
    cwd,
    help,
    plain,
    filter,
    output_file,
    current_file,
    debug_scores,
    hide_scores,
};

pub const FlagMetadata = struct {
    id: Flag,
    short: ?[]const u8 = null,
    long: []const u8,
    value_name: ?[]const u8 = null,
    description: []const u8,
};

const CommandMetadata = struct {
    name: []const u8,
    mode: Mode,
    description: []const u8,
    flags: []const Flag,
};

const metadata = [_]FlagMetadata{
    .{ .id = .help, .short = "-h", .long = "--help", .description = "Show help." },
    .{ .id = .plain, .short = "-p", .long = "--plain", .description = "Disable filepath ranking boosts." },
    .{ .id = .filter, .short = "-f", .long = "--filter", .value_name = "QUERY", .description = "Filter without interactive TUI." },
    .{ .id = .cwd, .long = "--cwd", .value_name = "PATH", .description = "Working directory for file discovery." },
    .{ .id = .output_file, .long = "--output-file", .value_name = "PATH", .description = "Write the selection after the TUI exits." },
    .{ .id = .current_file, .long = "--current-file", .value_name = "PATH", .description = "Current editor file path." },
    .{ .id = .debug_scores, .long = "--debug-scores", .description = "Print score breakdowns in filter mode." },
    .{ .id = .hide_scores, .long = "--hide-scores", .description = "Hide the score column in the interactive TUI." },
};

const stdin_flags = [_]Flag{
    .help,
    .plain,
    .filter,
    .output_file,
    .debug_scores,
    .hide_scores,
};
const files_flags = [_]Flag{
    .help,
    .plain,
    .filter,
    .cwd,
    .current_file,
    .output_file,
    .debug_scores,
    .hide_scores,
};

const commands = [_]CommandMetadata{
    .{ .name = "stdin", .mode = .stdin, .description = "Pick newline-delimited input from stdin.", .flags = &stdin_flags },
    .{ .name = "files", .mode = .files, .description = "Pick project files with Git-status ranking.", .flags = &files_flags },
    .{ .name = "candidates", .mode = .candidates, .description = "Pick JSONL candidates from stdin.", .flags = &stdin_flags },
};

pub fn parse(
    args: []const []const u8,
    stderr: *std.Io.Writer,
    stdout: *std.Io.Writer,
) Config {
    if (args.len < 2) usage(stderr, 2, null);

    if (isHelpFlag(args[1])) usage(stdout, 0, null);

    if (std.mem.eql(u8, args[1], "help")) {
        if (args.len == 2 or (args.len == 3 and isHelpFlag(args[2]))) usage(stdout, 0, null);
        if (args.len == 3) usage(stdout, 0, findCommand(args[2]) orelse usage(stderr, 2, null));
        usage(stderr, 2, null);
    }

    const command = findCommand(args[1]) orelse usage(stderr, 2, null);
    var config: Config = .{ .mode = command.mode };
    parseCommandFlags(&config, command, args, stderr, stdout);
    return config;
}

fn parseCommandFlags(
    config: *Config,
    command: *const CommandMetadata,
    args: []const []const u8,
    stderr: *std.Io.Writer,
    stdout: *std.Io.Writer,
) void {
    var index: usize = 2;
    while (index < args.len) : (index += 1) {
        const flag = findFlag(command, args[index]) orelse usage(stderr, 2, command);
        applyFlag(config, command, flag, args, &index, stderr, stdout);
    }
}

fn applyFlag(
    config: *Config,
    command: *const CommandMetadata,
    flag: Flag,
    args: []const []const u8,
    index: *usize,
    stderr: *std.Io.Writer,
    stdout: *std.Io.Writer,
) void {
    switch (flag) {
        .help => usage(stdout, 0, command),
        .cwd => config.cwd = nextArg(args, index, stderr, command),
        .plain => config.plain = true,
        .filter => config.filter = nextArg(args, index, stderr, command),
        .output_file => config.output_file = nextArg(args, index, stderr, command),
        .current_file => config.current_file = nextArg(args, index, stderr, command),
        .debug_scores => config.debug_scores = true,
        .hide_scores => config.show_scores = false,
    }
}

fn isHelpFlag(arg: []const u8) bool {
    const help = metadataForFlag(.help);
    return std.mem.eql(u8, arg, help.long) or std.mem.eql(u8, arg, help.short.?);
}

fn findCommand(name: []const u8) ?*const CommandMetadata {
    for (&commands) |*command| {
        if (std.mem.eql(u8, name, command.name)) return command;
    }
    return null;
}

fn findFlag(
    command: *const CommandMetadata,
    name: []const u8,
) ?Flag {
    for (command.flags) |flag| {
        const flag_metadata = metadataForFlag(flag);
        if (std.mem.eql(u8, name, flag_metadata.long)) return flag;
        if (flag_metadata.short) |short| {
            if (std.mem.eql(u8, name, short)) return flag;
        }
    }
    return null;
}

fn metadataForFlag(flag: Flag) *const FlagMetadata {
    for (&metadata) |*item| {
        if (item.id == flag) return item;
    }
    unreachable;
}

fn nextArg(
    args: []const []const u8,
    index: *usize,
    stderr: *std.Io.Writer,
    command: *const CommandMetadata,
) []const u8 {
    index.* += 1;
    if (index.* >= args.len) usage(stderr, 2, command);
    return args[index.*];
}

fn usage(
    writer: *std.Io.Writer,
    code: u8,
    command: ?*const CommandMetadata,
) noreturn {
    writeUsage(writer, command) catch unreachable;
    writer.flush() catch unreachable;
    std.process.exit(code);
}

fn writeUsage(
    writer: *std.Io.Writer,
    command: ?*const CommandMetadata,
) !void {
    if (command) |selected| {
        try writer.print("Usage: zt {s} [options]\n\n{s}\n\nOptions:\n", .{ selected.name, selected.description });
        const width = maxFlagLabelLength(selected.flags);
        for (selected.flags) |flag| try writeFlagHelp(writer, metadataForFlag(flag), width);
        return;
    }

    const help_command = "help [command]";
    var width = help_command.len;
    for (commands) |command_item| width = @max(width, command_item.name.len);

    try writer.writeAll("Usage: zt <command> [options]\n\nCommands:\n");
    for (commands) |command_item| try writeGridRow(writer, command_item.name, command_item.description, width);
    try writeGridRow(writer, help_command, "Show general or command-specific help.", width);
    try writer.writeAll("\nUse `zt help <command>` for command options.\n");
}

fn maxFlagLabelLength(flags: []const Flag) usize {
    var width: usize = 0;
    for (flags) |flag| width = @max(width, flagLabelLength(metadataForFlag(flag)));
    return width;
}

fn flagLabelLength(flag_metadata: *const FlagMetadata) usize {
    var length = flag_metadata.long.len;
    if (flag_metadata.short) |short| length += short.len + 2;
    if (flag_metadata.value_name) |value_name| length += value_name.len + 1;
    return length;
}

fn writeFlagHelp(
    writer: *std.Io.Writer,
    flag_metadata: *const FlagMetadata,
    width: usize,
) !void {
    var label_buf: [128]u8 = undefined;
    var label_writer: std.Io.Writer = .fixed(&label_buf);

    if (flag_metadata.short) |short| try label_writer.print("{s}, ", .{short});
    try label_writer.writeAll(flag_metadata.long);
    if (flag_metadata.value_name) |value_name| try label_writer.print(" {s}", .{value_name});

    try writeGridRow(writer, label_writer.buffered(), flag_metadata.description, width);
}

fn writeGridRow(
    writer: *std.Io.Writer,
    label: []const u8,
    description: []const u8,
    width: usize,
) !void {
    try writer.writeAll("  ");
    try writer.writeAll(label);
    for (label.len..width) |_| try writer.writeByte(' ');
    try writer.print("  {s}\n", .{description});
}

test "command metadata scopes flags" {
    const stdin_command = findCommand("stdin").?;
    const files_command = findCommand("files").?;

    try std.testing.expectEqual(Flag.filter, findFlag(stdin_command, "-f").?);
    try std.testing.expect(findFlag(stdin_command, "--cwd") == null);
    try std.testing.expectEqual(Flag.cwd, findFlag(files_command, "--cwd").?);
}
