const std = @import("std");
const vaxis = @import("vaxis");

const matcher = @import("match/mod.zig");
const files = @import("files/mod.zig");
const picker = @import("picker/mod.zig");
const actions = @import("picker/actions.zig");
const candidates = @import("candidates.zig");
const protocol = @import("picker/protocol.zig");
const GitStatus = @import("files/git.zig").GitStatus;
const flags = @import("flags.zig");
const Config = flags.Config;

pub const panic = vaxis.panic_handler;

const Standard = struct {
    const Self = @This();
    var stderr_buf: [1024]u8 = undefined;
    var stdout_buf: [1024]u8 = undefined;
    var stdin_buf: [1024]u8 = undefined;
    var stderr_writer: std.Io.File.Writer = undefined;
    var stdout_writer: std.Io.File.Writer = undefined;
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
    const allocator = init.arena.allocator();

    Standard.init(io);
    defer Standard.flushAll();

    const args = try init.minimal.args.toSlice(allocator);
    const config = flags.parse(args, Standard.err(), Standard.out());

    switch (config.mode) {
        .stdin => try runPick(Standard.out(), Standard.in(), init, allocator, config),
        .candidates => try runCandidates(Standard.out(), Standard.in(), init, allocator, config),
        .files => try runFiles(Standard.out(), init, allocator, config),
    }
}

fn runPick(
    stdout: *std.Io.Writer,
    stdin: *std.Io.Reader,
    init: std.process.Init,
    allocator: std.mem.Allocator,
    config: Config,
) !void {
    const input = try stdin.allocRemaining(allocator, .unlimited);
    const lines = try collectLines(allocator, input);
    var selection = try runPicker(
        stdout,
        init,
        allocator,
        config,
        .{ .lines = lines },
        .{ .plain = config.plain },
    );
    defer selection.deinit(allocator);
    if (selection.indexes.len == 0) std.process.exit(130);
    const result = try formatSelectedLines(allocator, lines, selection.indexes);
    defer allocator.free(result);
    try writeOutput(stdout, init.io, result, config.output_file);
}

fn runFiles(
    stdout: *std.Io.Writer,
    init: std.process.Init,
    allocator: std.mem.Allocator,
    config: Config,
) !void {
    const cwd = config.cwd orelse ".";
    const entries = try files.collectProjectEntries(allocator, init.io, cwd);
    const lines = try allocator.alloc([]const u8, entries.len);
    const git_statuses = try allocator.alloc(GitStatus, entries.len);
    for (entries, 0..) |entry, index| {
        lines[index] = entry.path;
        git_statuses[index] = entry.git_status;
    }
    var selection = try runPicker(
        stdout,
        init,
        allocator,
        config,
        .{ .lines = lines, .git_statuses = git_statuses },
        .{ .plain = config.plain, .current_file = relativeCurrentFile(cwd, config.current_file) },
    );
    defer selection.deinit(allocator);
    if (selection.indexes.len == 0) std.process.exit(130);
    const paths = try collectSelectedLines(allocator, lines, selection.indexes);
    defer allocator.free(paths);
    const result = try protocol.formatActionResult(allocator, selection.action, paths);
    defer allocator.free(result);
    try writeOutput(stdout, init.io, result, config.output_file);
}

fn runCandidates(
    stdout: *std.Io.Writer,
    stdin: *std.Io.Reader,
    init: std.process.Init,
    allocator: std.mem.Allocator,
    config: Config,
) !void {
    const input = try stdin.allocRemaining(allocator, .unlimited);
    const parsed = try candidates.parseJsonl(allocator, input);
    defer candidates.deinitCandidates(allocator, parsed);
    const match_lines = try allocator.alloc([]const u8, parsed.len);
    const display_lines = try allocator.alloc([]const u8, parsed.len);
    for (parsed, 0..) |candidate, index| {
        match_lines[index] = candidate.match_text;
        display_lines[index] = candidate.display_text;
    }
    var selection = try runPicker(
        stdout,
        init,
        allocator,
        config,
        .{ .lines = match_lines, .display_texts = display_lines },
        .{ .plain = config.plain },
    );
    defer selection.deinit(allocator);
    if (selection.indexes.len == 0) std.process.exit(130);
    const result = try formatCandidateSelection(allocator, parsed, selection);
    defer allocator.free(result);
    try writeOutput(stdout, init.io, result, config.output_file);
}

fn runPicker(
    stdout: *std.Io.Writer,
    init: std.process.Init,
    allocator: std.mem.Allocator,
    config: Config,
    source: picker.SourceData,
    rank_options: matcher.RankOptions,
) !picker.Selection {
    if (config.filter) |query| {
        const terms = try matcher.parseQuery(allocator, query);
        var filter_options = rank_options;
        filter_options.case_sensitive = matcher.hasUpper(query);
        const ranked = try matcher.rankQueryTop(allocator, source.lines, terms, filter_options, source.lines.len);
        if (ranked.len == 0) std.process.exit(1);
        writeRanked(stdout, ranked, source.display_texts, config.debug_scores) catch std.process.exit(0);
        stdout.flush() catch std.process.exit(0);
        std.process.exit(0);
    }

    return picker.run(init, allocator, source, rank_options, config.show_scores, "");
}

fn writeRanked(
    stdout: *std.Io.Writer,
    ranked: []const matcher.RankedLine,
    display_texts: ?[]const []const u8,
    debug_scores: bool,
) !void {
    for (ranked) |line| {
        const text = if (display_texts) |display| display[line.source_index] else line.text;
        if (debug_scores) {
            try stdout.print(
                "{d:.2}\tfz={d:.2}\tfn={d:.2}\tex={d:.2}\tcf={d:.2}\t{s}\n",
                .{
                    line.score.total(),
                    line.score.fuzzy,
                    line.score.filename_boost,
                    line.score.exact_filename_boost,
                    line.score.current_file_penalty,
                    text,
                },
            );
        } else {
            try stdout.print("{s}\n", .{text});
        }
    }
}

fn collectSelectedLines(
    allocator: std.mem.Allocator,
    lines: []const []const u8,
    indexes: []const usize,
) ![]const []const u8 {
    const selected = try allocator.alloc([]const u8, indexes.len);
    for (indexes, 0..) |index, position| selected[position] = lines[index];
    return selected;
}

fn formatSelectedLines(
    allocator: std.mem.Allocator,
    lines: []const []const u8,
    indexes: []const usize,
) ![]const u8 {
    var result: std.Io.Writer.Allocating = .init(allocator);
    errdefer result.deinit();
    for (indexes) |index| {
        try result.writer.writeAll(lines[index]);
        try result.writer.writeByte('\n');
    }
    return result.toOwnedSlice();
}

fn formatCandidateSelection(
    allocator: std.mem.Allocator,
    parsed: []const candidates.Candidate,
    selection: picker.Selection,
) ![]const u8 {
    var entries: std.ArrayList(protocol.ResultEntry) = .empty;
    defer entries.deinit(allocator);
    for (selection.indexes) |index| {
        const candidate = parsed[index];
        var action = selection.action;
        if (action == .edit) {
            if (candidate.default_action) |label| action = actions.Action.parse(label) orelse unreachable;
        }
        try entries.append(allocator, .{ .action = action, .output = candidate.output });
    }
    return protocol.formatResults(allocator, entries.items);
}

fn writeOutput(
    stdout: *std.Io.Writer,
    io: std.Io,
    result: []const u8,
    output_file: ?[]const u8,
) !void {
    if (output_file) |path| {
        try std.Io.Dir.writeFile(.cwd(), io, .{ .sub_path = path, .data = result });
        return;
    }
    try stdout.writeAll(result);
}

fn relativeCurrentFile(
    cwd: []const u8,
    current_file: ?[]const u8,
) ?[]const u8 {
    const file = current_file orelse return null;
    if (file.len == 0) return null;
    if (std.mem.eql(u8, file, cwd)) return null;
    if (std.mem.startsWith(u8, file, cwd)) {
        const rest = file[cwd.len..];
        if (rest.len > 0 and (rest[0] == '/' or rest[0] == '\\')) return rest[1..];
    }
    return file;
}

fn collectLines(
    allocator: std.mem.Allocator,
    input: []const u8,
) ![]const []const u8 {
    var lines: std.ArrayList([]const u8) = .empty;
    var iter = std.mem.splitScalar(u8, std.mem.trim(u8, input, "\n"), '\n');
    while (iter.next()) |line| {
        if (line.len == 0) continue;
        try lines.append(allocator, line);
    }
    return lines.toOwnedSlice(allocator);
}

test {
    _ = actions;
    _ = files;
    _ = matcher;
    _ = picker;
    _ = @import("picker/key_decoder.zig");
    _ = @import("picker/reducer.zig");
    _ = @import("picker/state.zig");
    _ = @import("picker/protocol.zig");
    _ = @import("picker/results.zig");
    _ = @import("candidates.zig");
}
