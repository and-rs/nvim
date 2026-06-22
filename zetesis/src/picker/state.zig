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

    pub fn init(allocator: std.mem.Allocator) State {
        return .{ .allocator = allocator };
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

test "state preserves per-mode query and cursor" {
    var state = State.init(std.testing.allocator);
    defer state.deinit();

    try state.setQuery("src");
    state.saveCursor(3);
    state.switchMode(.help, 3);
    try std.testing.expectEqualStrings("", state.currentQuery());
    try state.setQuery("split");
    state.saveCursor(1);

    state.switchMode(.files, 1);
    try std.testing.expectEqualStrings("src", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 3), state.wantedCursor());

    state.switchMode(.help, 3);
    try std.testing.expectEqualStrings("split", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 1), state.wantedCursor());
}

test "state restores file query and cursor after help search" {
    var state = State.init(std.testing.allocator);
    defer state.deinit();

    try state.setQuery("picker");
    state.saveCursor(4);

    state.switchMode(.help, 4);
    try std.testing.expectEqualStrings("", state.currentQuery());
    try state.setQuery("split");
    state.saveCursor(2);

    state.switchMode(.files, 2);
    try std.testing.expectEqualStrings("picker", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 4), state.wantedCursor());

    state.switchMode(.help, 4);
    try std.testing.expectEqualStrings("split", state.currentQuery());
    try std.testing.expectEqual(@as(usize, 2), state.wantedCursor());
}

test "state clamps cursor to visible length" {
    var state = State.init(std.testing.allocator);
    defer state.deinit();

    state.saveCursor(10);
    try std.testing.expectEqual(@as(usize, 0), state.clampCursor(0));
    try std.testing.expectEqual(@as(usize, 2), state.clampCursor(3));
}
