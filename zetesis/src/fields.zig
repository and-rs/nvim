const std = @import("std");

pub fn project(allocator: std.mem.Allocator, line: []const u8, delimiter: ?[]const u8, specification: ?[]const u8) ![]u8 {
    const spec = specification orelse return allocator.dupe(u8, line);
    const separator = switchDelimiter(delimiter orelse " ");
    if (separator.len == 0) return error.InvalidDelimiter;

    var fields: std.ArrayList([]const u8) = .empty;
    defer fields.deinit(allocator);
    var split = std.mem.splitSequence(u8, line, separator);
    while (split.next()) |field| try fields.append(allocator, field);

    var output: std.Io.Writer.Allocating = .init(allocator);
    errdefer output.deinit();
    var specs = std.mem.splitScalar(u8, spec, ',');
    var first = true;
    while (specs.next()) |entry| {
        const range = try parseRange(entry, fields.items.len);
        for (range.start..range.end) |index| {
            if (!first) try output.writer.writeByte('\t');
            try output.writer.writeAll(fields.items[index]);
            first = false;
        }
    }
    return output.toOwnedSlice();
}

fn switchDelimiter(value: []const u8) []const u8 {
    if (std.mem.eql(u8, value, "\\t")) return "\t";
    return value;
}

const Range = struct { start: usize, end: usize };

fn parseRange(text: []const u8, len: usize) !Range {
    if (std.mem.indexOf(u8, text, "..")) |split| {
        const start = if (split == 0) 0 else try parseIndex(text[0..split], len);
        const end = if (split + 2 == text.len) len else try parseIndex(text[split + 2 ..], len);
        if (start > end) return error.InvalidField;
        return .{ .start = start, .end = end };
    }
    const index = try parseIndex(text, len);
    return .{ .start = index, .end = index + 1 };
}

fn parseIndex(text: []const u8, len: usize) !usize {
    const value = std.fmt.parseInt(usize, text, 10) catch return error.InvalidField;
    if (value == 0 or value > len) return error.InvalidField;
    return value - 1;
}
