const std = @import("std");
const recipes = @import("recipes.zig");

pub fn write(io: std.Io, name: []const u8, samples: []const f64) !void {
    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, "zig-out/sounds");

    var path_buffer: [128]u8 = undefined;
    const path = try std.fmt.bufPrint(&path_buffer, "zig-out/sounds/{s}", .{name});
    const file = try cwd.createFile(io, path, .{});
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var writer = file.writer(io, &buffer);
    const out = &writer.interface;
    const data_size = @as(u32, @intCast(samples.len * 2 * @sizeOf(i16)));

    try out.writeAll("RIFF");
    try writeU32(out, 36 + data_size);
    try out.writeAll("WAVEfmt ");
    try writeU32(out, 16);
    try writeU16(out, 1);
    try writeU16(out, 2);
    try writeU32(out, recipes.sample_rate);
    try writeU32(out, recipes.sample_rate * 2 * @sizeOf(i16));
    try writeU16(out, 2 * @sizeOf(i16));
    try writeU16(out, 16);
    try out.writeAll("data");
    try writeU32(out, data_size);

    for (samples) |sample| {
        const pcm = @as(i16, @intFromFloat(std.math.clamp(sample, -1, 1) * std.math.maxInt(i16)));
        try writeU16(out, @bitCast(pcm));
        try writeU16(out, @bitCast(pcm));
    }
    try out.flush();
}

fn writeU16(writer: *std.Io.Writer, value: u16) !void {
    try writer.writeAll(&.{ @truncate(value), @truncate(value >> 8) });
}

fn writeU32(writer: *std.Io.Writer, value: u32) !void {
    try writer.writeAll(&.{ @truncate(value), @truncate(value >> 8), @truncate(value >> 16), @truncate(value >> 24) });
}
