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
    stdin,
    files,
    help,
};

const Config = struct {
    mode: Mode = .stdin,
    filter: ?[]const u8 = null,
    cwd: ?[]const u8 = null,
    current_file: ?[]const u8 = null,
    output_file: ?[]const u8 = null,
    plain: bool = false,
    show_scores: bool = true,
    debug_scores: bool = false,
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
        .stdin => try runPick(init, allocator, config),
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
        try writeRanked(stdout, ranked, config.debug_scores);
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
        try writeRanked(stdout, ranked, config.debug_scores);
        return;
    }

    const result = try picker.run(init, allocator, lines, rank_options, config.show_scores);
    if (result.len == 0) std.process.exit(130);
    if (config.output_file) |path| {
        try std.Io.Dir.writeFile(.cwd(), init.io, .{ .sub_path = path, .data = result });
    } else {
        try stdout.writeAll(result);
    }
}

fn writeRanked(stdout: *std.Io.Writer, ranked: []const matcher.RankedLine, debug_scores: bool) !void {
    for (ranked) |line| {
        if (debug_scores) {
            try stdout.print(
                "{d:.2}\tfz={d:.2}\tfn={d:.2}\tex={d:.2}\tcf={d:.2}\t{s}\n",
                .{
                    line.score.total(),
                    line.score.fuzzy,
                    line.score.filename_boost,
                    line.score.exact_filename_boost,
                    line.score.current_file_penalty,
                    line.text,
                },
            );
        } else {
            try stdout.print("{s}\n", .{line.text});
        }
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

const subcommands = std.StaticStringMap(Mode).initComptime(.{
    .{ "files", .files },
    .{ "stdin", .stdin },
    .{ "help", .help },
});

const flags = std.StaticStringMap(Flag).initComptime(.{
    .{ "-h", .help },
    .{ "-p", .plain },
    .{ "-f", .filter },
    .{ "--cwd", .cwd },
    .{ "--help", .help },
    .{ "--plain", .plain },
    .{ "--filter", .filter },
    .{ "--output-file", .output_file },
    .{ "--current-file", .current_file },
    .{ "--debug-scores", .debug_scores },
    .{ "--hide-scores", .hide_scores },
});

fn parseArgs(args: []const []const u8, stderr: *std.Io.Writer) Config {
    if (args.len < 2) return usage(stderr, 2);

    const mode = subcommands.get(args[1]) orelse return usage(stderr, 2);
    var config: Config = .{ .mode = mode };
    var idx: usize = 2;

    switch (mode) {
        .help => return config,
        .stdin => parseStdinFlags(&config, args, &idx, stderr),
        .files => parseFilesFlags(&config, args, &idx, stderr),
    }

    return config;
}

fn parseStdinFlags(config: *Config, args: []const []const u8, idx: *usize, stderr: *std.Io.Writer) void {
    while (idx.* < args.len) : (idx.* += 1) {
        const flag = parseFlag(args[idx.*], stderr);
        switch (flag) {
            .cwd => usage(stderr, 2),
            else => applySharedFlag(config, flag, args, idx, stderr),
        }
    }
}

fn parseFilesFlags(config: *Config, args: []const []const u8, idx: *usize, stderr: *std.Io.Writer) void {
    while (idx.* < args.len) : (idx.* += 1) {
        const flag = parseFlag(args[idx.*], stderr);
        switch (flag) {
            .cwd => config.cwd = nextArg(args, idx, stderr),
            else => applySharedFlag(config, flag, args, idx, stderr),
        }
    }
}

fn applySharedFlag(config: *Config, flag: Flag, args: []const []const u8, idx: *usize, stderr: *std.Io.Writer) void {
    switch (flag) {
        .cwd => unreachable,
        .help => usage(stderr, 0),
        .plain => config.plain = true,
        .filter => config.filter = nextArg(args, idx, stderr),
        .output_file => config.output_file = nextArg(args, idx, stderr),
        .current_file => config.current_file = nextArg(args, idx, stderr),
        .debug_scores => config.debug_scores = true,
        .hide_scores => config.show_scores = false,
    }
}

fn parseFlag(arg: []const u8, stderr: *std.Io.Writer) Flag {
    return flags.get(arg) orelse usage(stderr, 2);
}

fn nextArg(args: []const []const u8, index: *usize, stderr: *std.Io.Writer) []const u8 {
    index.* += 1;
    if (index.* >= args.len) usage(stderr, 2);
    return args[index.*];
}

fn usage(stderr: *std.Io.Writer, code: u8) noreturn {
    stderr.writeAll(
        \\Usage: zt [stdin|files|help] [options]
        \\
        \\Options:
        \\  -f, --filter QUERY       Filter without interactive TUI.
        \\      --cwd PATH           Working directory for files mode.
        \\      --current-file PATH  Current editor file path.
        \\      --output-file PATH   Write selected item to file after TUI exits.
        \\  -p, --plain              Disable filepath ranking boosts.
        \\      --hide-scores        Hide score column in interactive TUI.
        \\      --debug-scores       Print score breakdown in filter mode.
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
