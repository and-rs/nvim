const std = @import("std");

const Action = @import("action.zig").Action;
const jsonl = @import("jsonl.zig");

pub const ResultEntry = struct {
    action: Action,
    output: jsonl.Output,
};

pub fn formatResults(allocator: std.mem.Allocator, entries: []const ResultEntry) ![]const u8 {
    var result: std.Io.Writer.Allocating = .init(allocator);
    errdefer result.deinit();

    for (entries) |entry| {
        try writeResult(&result.writer, entry);
        try result.writer.writeByte('\n');
    }

    return result.toOwnedSlice();
}

fn writeResult(writer: *std.Io.Writer, entry: ResultEntry) !void {
    var json: std.json.Stringify = .{ .writer = writer };
    try json.beginObject();
    try json.objectField("action");
    try json.write(entry.action.label());

    switch (entry.output) {
        .file => |file| {
            try json.objectField("kind");
            try json.write("file");
            try json.objectField("path");
            try json.write(file.path);
        },
        .location => |location| {
            try json.objectField("kind");
            try json.write("location");
            try json.objectField("path");
            try json.write(location.path);
            try json.objectField("line");
            try json.write(location.line);
            try json.objectField("col");
            try json.write(location.col);
            try json.objectField("text");
            try json.write(location.text);
        },
        .text => |text| {
            try json.objectField("kind");
            try json.write("text");
            try json.objectField("text");
            try json.write(text.text);
        },
    }

    try json.endObject();
}
