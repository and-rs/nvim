const std = @import("std");
const vaxis = @import("vaxis");
const zetesis = @import("zetesis");

const flags = zetesis.flags;
const picker = zetesis.picker;
const fuzzy = zetesis.match.fuzzy;
const path = zetesis.match.path;
const fields = zetesis.fields;

pub const panic = vaxis.panic_handler;

const Standard = struct {
    const Self = @This();
    var stderr_buf: [1024]u8 = undefined;
    var stdout_buf: [1024]u8 = undefined;
    var stderr_writer: std.Io.File.Writer = undefined;
    var stdout_writer: std.Io.File.Writer = undefined;
    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader: std.Io.File.Reader = undefined;
    fn init(io: std.Io) void {
        Self.stderr_writer = std.Io.File.stderr().writer(io, &Self.stderr_buf);
        Self.stdout_writer = std.Io.File.stdout().writer(io, &Self.stdout_buf);
        Self.stdin_reader = std.Io.File.stdin().reader(io, &Self.stdin_buf);
    }
    fn err() *std.Io.Writer {
        return &Self.stderr_writer.interface;
    }
    fn out() *std.Io.Writer {
        return &Self.stdout_writer.interface;
    }
    fn in() *std.Io.Reader {
        return &Self.stdin_reader.interface;
    }
    fn flushAll() void {
        Self.stderr_writer.interface.flush() catch {};
        Self.stdout_writer.interface.flush() catch {};
    }
};

pub fn main(init: std.process.Init) anyerror!void {
    const io = init.io;
    const arena = init.arena.allocator();
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    Standard.init(io);
    defer Standard.flushAll();

    const args = try init.minimal.args.toSlice(arena);
    const config = flags.parse(args, Standard.err(), Standard.out());

    switch (config.mode) {
        .stdin => try runStdin(init, gpa, config),
        .files => try runFiles(init, gpa, config),
    }
}

fn runStdin(init: std.process.Init, allocator: std.mem.Allocator, config: flags.Config) !void {
    const input = try Standard.in().allocRemaining(allocator, .unlimited);
    const lines = try collectLines(allocator, input);
    const source = try projectInput(allocator, lines, config);
    if (config.filter) |query| {
        try writeFiltered(allocator, source, query, config.matcher);
        return;
    }

    var selection = try picker.runStatic(init, allocator, source, .{
        .output_file = config.output_file,
        .action_file = config.action_file,
        .match_mode = switch (config.matcher) {
            .fuzzy => .fuzzy,
            .path => .path,
        },
    });
    defer selection.deinit(allocator);
    if (selection.paths.len == 0) std.process.exit(130);
    const output = try picker.formatSelection(allocator, selection);
    defer allocator.free(output);
    try picker.writeOutput(init.io, Standard.out(), output, config.output_file);
    try picker.writeAction(init.io, selection.action, config.action_file);
}

fn projectInput(allocator: std.mem.Allocator, lines: []const []const u8, config: flags.Config) !picker.StaticSource {
    const match = try allocator.alloc([]const u8, lines.len);
    const display = try allocator.alloc([]const u8, lines.len);
    const output = try allocator.alloc([]const u8, lines.len);
    for (lines, 0..) |line, i| {
        match[i] = try fields.project(allocator, line, config.delimiter, config.nth);
        display[i] = try fields.project(allocator, line, config.delimiter, config.with_nth);
        output[i] = try fields.project(allocator, line, config.delimiter, config.accept_nth);
    }
    return .{ .match = match, .display = display, .output = output };
}

fn runFiles(init: std.process.Init, allocator: std.mem.Allocator, config: flags.Config) !void {
    const cwd: std.process.Child.Cwd = if (config.cwd) |cwd_path| .{ .path = cwd_path } else .inherit;
    var selection = picker.run(init, allocator, .{
        .cwd = cwd,
        .output_file = config.output_file,
        .action_file = config.action_file,
        .current_file = relativeCurrentFile(config.cwd, config.current_file),
        .plain = config.plain,
    }) catch |err| switch (err) {
        error.FdMissing => {
            try Standard.err().writeAll("fd binary missing\n");
            std.process.exit(1);
        },
        else => |e| return e,
    };
    defer selection.deinit(allocator);

    if (selection.paths.len == 0) std.process.exit(130);

    const payload = try picker.formatSelection(allocator, selection);
    defer allocator.free(payload);
    try picker.writeOutput(init.io, Standard.out(), payload, config.output_file);
    try picker.writeAction(init.io, selection.action, config.action_file);
}

fn collectLines(allocator: std.mem.Allocator, input: []const u8) ![]const []const u8 {
    var lines: std.ArrayList([]const u8) = .empty;
    var iter = std.mem.splitScalar(u8, input, '\n');
    while (iter.next()) |line| if (line.len > 0) try lines.append(allocator, line);
    return lines.toOwnedSlice(allocator);
}

const Filtered = struct {
    line: []const u8,
    score: i32,
};

fn writeFiltered(allocator: std.mem.Allocator, source: picker.StaticSource, query: []const u8, mode: flags.Matcher) !void {
    var matches: std.ArrayList(Filtered) = .empty;
    defer matches.deinit(allocator);
    for (source.match, 0..) |line, index| {
        const score = switch (mode) {
            .fuzzy => fuzzy.score(line, query, fuzzy.hasUpper(query)),
            .path => path.score(line, query, .{}),
        } orelse continue;
        try matches.append(allocator, .{ .line = source.output[index], .score = score });
    }
    std.mem.sort(Filtered, matches.items, {}, filteredBefore);
    for (matches.items) |entry| try Standard.out().print("{s}\n", .{entry.line});
}

fn filteredBefore(_: void, left: Filtered, right: Filtered) bool {
    if (left.score != right.score) return left.score > right.score;
    return std.mem.lessThan(u8, left.line, right.line);
}

fn relativeCurrentFile(cwd: ?[]const u8, current_file: ?[]const u8) ?[]const u8 {
    const file = current_file orelse return null;
    const root = cwd orelse return file;
    if (std.mem.startsWith(u8, file, root)) {
        const rest = file[root.len..];
        if (rest.len > 0 and (rest[0] == '/' or rest[0] == '\\')) return rest[1..];
    }
    return file;
}
