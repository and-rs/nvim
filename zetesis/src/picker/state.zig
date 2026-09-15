const std = @import("std");

pub const Mode = enum {
    files,
    help,
};

pub const State = struct {
    allocator: std.mem.Allocator,
    mode: Mode = .files,
    file_query: []const u8 = "",
    help_query: []const u8 = "",
    file_cursor: usize = 0,
    help_cursor: usize = 0,

    pub fn init(allocator: std.mem.Allocator, initial_query: []const u8) !State {
        var result: State = .{ .allocator = allocator };
        if (initial_query.len > 0) result.file_query = try allocator.dupe(u8, initial_query);
        return result;
    }

    pub fn deinit(self: *State) void {
        if (self.file_query.len > 0) self.allocator.free(self.file_query);
        if (self.help_query.len > 0) self.allocator.free(self.help_query);
    }
    pub fn currentQuery(self: *const State) []const u8 {
        return switch (self.mode) {
            .files => self.file_query,
            .help => self.help_query,
        };
    }

    pub fn setQuery(self: *State, query: []const u8) !void {
        switch (self.mode) {
            .files => try self.replaceQuery(&self.file_query, query),
            .help => try self.replaceQuery(&self.help_query, query),
        }
    }

    pub fn saveCursor(self: *State, cursor: usize) void {
        switch (self.mode) {
            .files => self.file_cursor = cursor,
            .help => self.help_cursor = cursor,
        }
    }

    pub fn wantedCursor(self: *const State) usize {
        return switch (self.mode) {
            .files => self.file_cursor,
            .help => self.help_cursor,
        };
    }

    pub fn switchMode(self: *State, mode: Mode, cursor: usize) void {
        self.saveCursor(cursor);
        self.mode = mode;
    }

    pub fn clampCursor(self: *const State, len: usize) usize {
        if (len == 0) return 0;
        return @min(self.wantedCursor(), len - 1);
    }

    fn replaceQuery(self: *State, slot: *[]const u8, query: []const u8) !void {
        if (slot.*.len > 0) self.allocator.free(slot.*);
        slot.* = if (query.len == 0) "" else try self.allocator.dupe(u8, query);
    }
};
