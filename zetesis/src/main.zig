const std = @import("std");
const vaxis = @import("vaxis");
const zetesis = @import("zetesis");

const flags = zetesis.flags;
const picker = zetesis.picker;

pub const panic = vaxis.panic_handler;

const Standard = struct {
    const Self = @This();
    var stderr_buf: [1024]u8 = undefined;
    var stdout_buf: [1024]u8 = undefined;
    var stderr_writer: std.Io.File.Writer = undefined;
    var stdout_writer: std.Io.File.Writer = undefined;
    fn init(io: std.Io) void {
        Self.stderr_writer = std.Io.File.stderr().writer(io, &Self.stderr_buf);
        Self.stdout_writer = std.Io.File.stdout().writer(io, &Self.stdout_buf);
    }
    fn err() *std.Io.Writer {
        return &Self.stderr_writer.interface;
    }
    fn out() *std.Io.Writer {
        return &Self.stdout_writer.interface;
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
        .stdin => {
            try Standard.err().writeAll("stdin mode is not wired yet\n");
            std.process.exit(1);
        },
        .files => try runFiles(init, allocator, config),
    }
}

fn runFiles(init: std.process.Init, allocator: std.mem.Allocator, config: flags.Config) !void {
    const cwd: std.process.Child.Cwd = if (config.cwd) |path| .{ .path = path } else .inherit;
    var selection = picker.run(init, allocator, .{
        .cwd = cwd,
        .output_file = config.output_file,
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
}
