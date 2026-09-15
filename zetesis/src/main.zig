const std = @import("std");
const vaxis = @import("vaxis");
const zetesis = @import("zetesis");

const flags = zetesis.flags;

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
    _ = flags.parse(args, Standard.err(), Standard.out());
}
