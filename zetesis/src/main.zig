const std = @import("std");
const vaxis = @import("vaxis");

const matcher = @import("matcher.zig");
const files = @import("files.zig");
const picker = @import("picker.zig");
const actions = @import("actions.zig");
const key_decoder = @import("key_decoder.zig");
const picker_reducer = @import("picker_reducer.zig");
const picker_state = @import("picker_state.zig");

pub const panic = vaxis.panic_handler;

const Mode = enum {
    pick,
    files,
    help,
};

const Config = struct {
    mode: Mode = .pick,
    filter: ?[]const u8 = null,
    cwd: ?[]const u8 = null,
    current_file: ?[]const u8 = null,
    output_file: ?[]const u8 = null,
    plain: bool = false,
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const allocator = init.arena.allocator();

    var stderr_file: std.Io.File = .stderr();
    var stderr_buf: [1024]u8 = undefined;
    var stderr_writer = stderr_file.writer(io, &stderr_buf);
    const stderr = &stderr_writer.interface;

    const args = try init.minimal.args.toSlice(allocator);
    const config = parseArgs(args, stderr);

    switch (config.mode) {
        .pick => try runPick(init, allocator, config),
        .files => try runFiles(init, allocator, config),
        .help => try runHelp(init, allocator, config),
    }
}

fn runPick(init: std.process.Init, allocator: std.mem.Allocator, config: Config) !void {
    const input = try readStdin(init.io, allocator);
    const lines = try collectLines(allocator, input);
    try runPicker(init, allocator, config, lines, .{ .plain = config.plain });
}

fn runFiles(init: std.process.Init, allocator: std.mem.Allocator, config: Config) !void {
    const cwd = config.cwd orelse ".";
    const lines = try files.collectProjectFiles(allocator, init.io, cwd);
    try runPicker(init, allocator, config, lines, .{ .plain = config.plain, .current_file = relativeCurrentFile(cwd, config.current_file) });
}

fn runHelp(init: std.process.Init, allocator: std.mem.Allocator, config: Config) !void {
    var stdout_file: std.Io.File = .stdout();
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = stdout_file.writer(init.io, &stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch unreachable;

    if (config.filter) |query| {
        const needles = try matcher.splitQuery(allocator, query);
        const ranked = try matcher.rankAndSort(allocator, actions.help_lines[0..], needles, .{ .plain = true, .case_sensitive = matcher.hasUpper(query) });
        if (ranked.len == 0) std.process.exit(1);
        for (ranked) |line| {
            try stdout.print("{s}\n", .{line.text});
        }
        return;
    }

    for (actions.help_lines) |line| {
        try stdout.print("{s}\n", .{line});
    }
}

fn runPicker(init: std.process.Init, allocator: std.mem.Allocator, config: Config, lines: []const []const u8, rank_options: matcher.RankOptions) !void {
    var stdout_file: std.Io.File = .stdout();
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = stdout_file.writer(init.io, &stdout_buf);
    const stdout = &stdout_writer.interface;
    defer stdout.flush() catch unreachable;

    if (config.filter) |query| {
        const needles = try matcher.splitQuery(allocator, query);
        var filter_options = rank_options;
        filter_options.case_sensitive = matcher.hasUpper(query);
        const ranked = try matcher.rankAndSort(allocator, lines, needles, filter_options);
        if (ranked.len == 0) std.process.exit(1);
        for (ranked) |line| {
            try stdout.print("{s}\n", .{line.text});
        }
        return;
    }

    const result = try picker.run(init, allocator, lines, rank_options);
    if (result.len == 0) std.process.exit(130);
    if (config.output_file) |path| {
        try std.Io.Dir.writeFile(.cwd(), init.io, .{ .sub_path = path, .data = result });
    } else {
        try stdout.writeAll(result);
    }
}

fn relativeCurrentFile(cwd: []const u8, current_file: ?[]const u8) ?[]const u8 {
    const file = current_file orelse return null;
    if (file.len == 0) return null;
    if (std.mem.eql(u8, file, cwd)) return null;

    if (std.mem.startsWith(u8, file, cwd)) {
        const rest = file[cwd.len..];
        if (rest.len > 0 and (rest[0] == '/' or rest[0] == '\\')) return rest[1..];
    }

    return file;
}

fn readStdin(io: std.Io, allocator: std.mem.Allocator) ![]const u8 {
    var stdin_file: std.Io.File = .stdin();
    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = stdin_file.reader(io, &stdin_buf);
    const stdin = &stdin_reader.interface;
    return stdin.allocRemaining(allocator, .unlimited);
}

fn collectLines(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    var lines: std.ArrayList([]const u8) = .empty;
    var iter = std.mem.splitScalar(u8, std.mem.trim(u8, input, "\n"), '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, line);
    }
    return lines.toOwnedSlice(allocator);
}

fn collectLinesDuped(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    var lines: std.ArrayList([]const u8) = .empty;
    var iter = std.mem.splitScalar(u8, std.mem.trim(u8, input, "\n"), '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, try allocator.dupe(u8, line));
    }
    return lines.toOwnedSlice(allocator);
}

fn parseArgs(args: []const []const u8, stderr: *std.Io.Writer) Config {
    var config: Config = .{};
    var index: usize = 1;

    if (index < args.len and !std.mem.startsWith(u8, args[index], "-")) {
        if (std.mem.eql(u8, args[index], "pick")) {
            config.mode = .pick;
        } else if (std.mem.eql(u8, args[index], "files")) {
            config.mode = .files;
        } else if (std.mem.eql(u8, args[index], "help")) {
            config.mode = .help;
        } else {
            usage(stderr, 2);
        }
        index += 1;
    }

    while (index < args.len) : (index += 1) {
        const arg = args[index];
        if (std.mem.eql(u8, arg, "--filter") or std.mem.eql(u8, arg, "-f")) {
            config.filter = nextArg(args, &index, stderr);
        } else if (std.mem.eql(u8, arg, "--cwd")) {
            config.cwd = nextArg(args, &index, stderr);
        } else if (std.mem.eql(u8, arg, "--current-file")) {
            config.current_file = nextArg(args, &index, stderr);
        } else if (std.mem.eql(u8, arg, "--output-file")) {
            config.output_file = nextArg(args, &index, stderr);
        } else if (std.mem.eql(u8, arg, "--plain") or std.mem.eql(u8, arg, "-p")) {
            config.plain = true;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            usage(stderr, 0);
        } else {
            usage(stderr, 2);
        }
    }

    return config;
}

fn nextArg(args: []const []const u8, index: *usize, stderr: *std.Io.Writer) []const u8 {
    index.* += 1;
    if (index.* >= args.len) usage(stderr, 2);
    return args[index.*];
}

fn usage(stderr: *std.Io.Writer, code: u8) noreturn {
    stderr.writeAll(
        \\Usage: zt [pick|files|help] [options]
        \\
        \\Options:
        \\  -f, --filter QUERY       Filter without interactive TUI.
        \\      --cwd PATH           Working directory for files mode.
        \\      --current-file PATH  Current editor file path.
        \\      --output-file PATH   Write selected item to file after TUI exits.
        \\  -p, --plain              Disable filepath ranking boosts.
        \\  -h, --help               Show help.
        \\
    ) catch unreachable;
    stderr.flush() catch unreachable;
    std.process.exit(code);
}

test {
    _ = actions;
    _ = files;
    _ = key_decoder;
    _ = matcher;
    _ = picker;
    _ = picker_reducer;
    _ = picker_state;
}
