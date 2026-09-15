const std = @import("std");
const Action = @import("picker/actions.zig").Action;

pub const ParseError = error{
    InvalidJson,
    ExpectedObject,
    UnknownKind,
    MissingPath,
    MissingLine,
    MissingText,
    InvalidFieldType,
    InvalidAction,
};

pub const Kind = enum {
    file,
    location,
    text,
};

pub const FileOutput = struct {
    path: []const u8,
};

pub const LocationOutput = struct {
    path: []const u8,
    line: usize,
    col: usize,
    text: []const u8,
};

pub const TextOutput = struct {
    text: []const u8,
};

pub const Output = union(Kind) {
    file: FileOutput,
    location: LocationOutput,
    text: TextOutput,
};

pub const Candidate = struct {
    match_text: []const u8,
    display_text: []const u8,
    output: Output,
    default_action: ?[]const u8 = null,

    pub fn deinit(self: *Candidate, allocator: std.mem.Allocator) void {
        allocator.free(self.match_text);
        allocator.free(self.display_text);
        if (self.default_action) |action| allocator.free(action);

        deinitOutput(allocator, self.output);
    }
};

pub fn deinitCandidates(allocator: std.mem.Allocator, candidates: []Candidate) void {
    for (candidates) |*candidate| candidate.deinit(allocator);
    allocator.free(candidates);
}

pub fn parseJsonl(allocator: std.mem.Allocator, input: []const u8) (std.mem.Allocator.Error || ParseError)![]Candidate {
    var candidates: std.ArrayList(Candidate) = .empty;
    errdefer {
        for (candidates.items) |*candidate| candidate.deinit(allocator);
        candidates.deinit(allocator);
    }

    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0) continue;
        try candidates.append(allocator, try parseLine(allocator, trimmed));
    }

    return candidates.toOwnedSlice(allocator);
}

const RawCandidate = struct {
    kind: Kind,
    text: ?[]const u8 = null,
    match: ?[]const u8 = null,
    display: ?[]const u8 = null,
    path: ?[]const u8 = null,
    line: ?usize = null,
    col: ?usize = null,
    action: ?[]const u8 = null,
};

fn parseLine(allocator: std.mem.Allocator, line: []const u8) (std.mem.Allocator.Error || ParseError)!Candidate {
    var arena_impl = std.heap.ArenaAllocator.init(allocator);
    defer arena_impl.deinit();

    const parsed = std.json.parseFromSliceLeaky(std.json.Value, arena_impl.allocator(), line, .{}) catch return error.InvalidJson;
    const raw = try parseRawCandidate(parsed);
    return normalizeCandidate(allocator, raw);
}

fn parseRawCandidate(value: std.json.Value) ParseError!RawCandidate {
    const object = switch (value) {
        .object => |object| object,
        else => return error.ExpectedObject,
    };

    return .{
        .kind = try parseKind(object.get("kind") orelse return error.InvalidFieldType),
        .text = try optionalString(object.get("text")),
        .match = try optionalString(object.get("match")),
        .display = try optionalString(object.get("display")),
        .path = try optionalString(object.get("path")),
        .line = try optionalPositiveInt(object.get("line")),
        .col = try optionalPositiveInt(object.get("col")),
        .action = try optionalString(object.get("action")),
    };
}

fn parseKind(value: std.json.Value) ParseError!Kind {
    const name = switch (value) {
        .string => |name| name,
        else => return error.InvalidFieldType,
    };

    if (std.mem.eql(u8, name, "file")) return .file;
    if (std.mem.eql(u8, name, "location")) return .location;
    if (std.mem.eql(u8, name, "text")) return .text;
    return error.UnknownKind;
}

fn optionalString(value: ?std.json.Value) ParseError!?[]const u8 {
    const inner = value orelse return null;
    return switch (inner) {
        .string => |text| text,
        .null => null,
        else => error.InvalidFieldType,
    };
}

fn optionalPositiveInt(value: ?std.json.Value) ParseError!?usize {
    const inner = value orelse return null;
    return switch (inner) {
        .integer => |number| {
            if (number <= 0) return error.InvalidFieldType;
            return std.math.cast(usize, number) orelse return error.InvalidFieldType;
        },
        .null => null,
        else => error.InvalidFieldType,
    };
}

fn normalizeCandidate(allocator: std.mem.Allocator, raw: RawCandidate) (std.mem.Allocator.Error || ParseError)!Candidate {
    const output = try normalizeOutput(allocator, raw);
    errdefer deinitOutput(allocator, output);

    const match_source = raw.match orelse raw.text orelse raw.display orelse raw.path orelse switch (output) {
        .text => |text| text.text,
        .location => |location| location.text,
        .file => return error.MissingText,
    };

    const display_source = raw.display orelse raw.text orelse raw.path orelse switch (output) {
        .text => |text| text.text,
        .location => |location| location.text,
        .file => return error.MissingText,
    };

    const match_text = try allocator.dupe(u8, match_source);
    errdefer allocator.free(match_text);

    const display_text = try allocator.dupe(u8, display_source);
    errdefer allocator.free(display_text);

    if (raw.action) |action| {
        if (Action.parse(action) == null) return error.InvalidAction;
    }
    const default_action = if (raw.action) |action| try allocator.dupe(u8, action) else null;
    errdefer if (default_action) |action| allocator.free(action);

    return .{
        .match_text = match_text,
        .display_text = display_text,
        .output = output,
        .default_action = default_action,
    };
}

fn normalizeOutput(allocator: std.mem.Allocator, raw: RawCandidate) (std.mem.Allocator.Error || ParseError)!Output {
    return switch (raw.kind) {
        .file => .{ .file = .{
            .path = try allocator.dupe(u8, raw.path orelse return error.MissingPath),
        } },
        .location => .{ .location = .{
            .path = try allocator.dupe(u8, raw.path orelse return error.MissingPath),
            .line = raw.line orelse return error.MissingLine,
            .col = raw.col orelse 1,
            .text = try allocator.dupe(u8, raw.text orelse raw.display orelse raw.path orelse return error.MissingText),
        } },
        .text => .{ .text = .{
            .text = try allocator.dupe(u8, raw.text orelse raw.display orelse raw.match orelse return error.MissingText),
        } },
    };
}

fn deinitOutput(allocator: std.mem.Allocator, output: Output) void {
    switch (output) {
        .file => |file| allocator.free(file.path),
        .location => |location| {
            allocator.free(location.path);
            allocator.free(location.text);
        },
        .text => |text| allocator.free(text.text),
    }
}
