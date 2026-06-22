const std = @import("std");
const vaxis = @import("vaxis");

const vxfw = vaxis.vxfw;

const Row = @This();

pub const GitStatus = enum {
    none,
    modified,
    added,
    untracked,
    deleted,
    renamed,
};

pub const Styles = struct {
    normal: vaxis.Style = .{},
    current: vaxis.Style = .{ .bold = true, .fg = .{ .index = 2 }, .bg = .{ .index = 0 } },
    marker: vaxis.Style = .{ .fg = .{ .index = 2 } },
    git: vaxis.Style = .{ .fg = .{ .index = 3 } },
    score: vaxis.Style = .{ .fg = .{ .index = 8 } },
    match: vaxis.Style = .{ .bold = true, .fg = .{ .index = 11 } },
};

text: []const u8,
index: usize,
cursor: *const u32,
marked: bool = false,
git_status: GitStatus = .none,
score_text: ?[]const u8 = null,
match_indexes: []const usize = &.{},
styles: Styles = .{},

pub fn widget(self: *const Row) vxfw.Widget {
    return .{
        .userdata = @constCast(self),
        .drawFn = Row.typeErasedDrawFn,
    };
}

fn typeErasedDrawFn(ptr: *anyopaque, ctx: vxfw.DrawContext) std.mem.Allocator.Error!vxfw.Surface {
    const self: *const Row = @ptrCast(@alignCast(ptr));
    const max = ctx.max.size();
    const surface = try vxfw.Surface.init(ctx.arena, self.widget(), .{ .width = max.width, .height = 1 });
    const base_style = if (self.isCurrent()) self.styles.current else self.styles.normal;
    @memset(surface.buffer, .{ .style = base_style });

    if (max.width == 0) return surface;

    var marker_style = self.styles.marker;
    marker_style.bg = base_style.bg;

    var git_style = self.styles.git;
    git_style.bg = base_style.bg;

    var score_style = self.styles.score;
    score_style.bg = base_style.bg;

    var match_style = self.styles.match;
    match_style.bg = base_style.bg;

    self.writeCell(surface, 0, cursorMarker(self.isCurrent()), marker_style);
    if (max.width > 1) self.writeCell(surface, 1, markMarker(self.marked), marker_style);
    var text_end: u16 = max.width;
    if (self.score_text) |score_text| {
        const score_width: u16 = @intCast(ctx.stringWidth(score_text));
        if (score_width > 0 and score_width + 5 <= text_end) {
            const score_start = text_end - score_width;
            const status_col = score_start - 2;
            self.writeCell(surface, status_col, gitMarker(self.git_status), git_style);
            self.writeText(ctx, surface, score_start, text_end, score_text, score_style);
            text_end = status_col - 1;
        }
    } else if (max.width > 4) {
        self.writeCell(surface, max.width - 1, gitMarker(self.git_status), git_style);
        text_end = max.width - 3;
    }

    const text_start: u16 = if (max.width > 2) 2 else max.width;
    self.writeMatchedText(ctx, surface, text_start, text_end, base_style, match_style);
    return surface;
}

fn isCurrent(self: Row) bool {
    return self.index == self.cursor.*;
}

fn writeCell(_: Row, surface: vxfw.Surface, col: u16, text: []const u8, style: vaxis.Style) void {
    surface.writeCell(col, 0, .{
        .char = .{ .grapheme = text, .width = 1 },
        .style = style,
    });
}

fn writeText(_: Row, ctx: vxfw.DrawContext, surface: vxfw.Surface, start: u16, end: u16, text: []const u8, style: vaxis.Style) void {
    if (start >= end) return;

    var col = start;
    var iter = ctx.graphemeIterator(text);
    while (iter.next()) |entry| {
        if (col >= end) break;
        const grapheme = entry.bytes(text);
        const width: u8 = @intCast(ctx.stringWidth(grapheme));
        if (width == 0 or col + width > end) break;
        surface.writeCell(col, 0, .{
            .char = .{ .grapheme = grapheme, .width = width },
            .style = style,
        });
        col += width;
    }
}

fn writeMatchedText(self: Row, ctx: vxfw.DrawContext, surface: vxfw.Surface, start: u16, end: u16, base_style: vaxis.Style, match_style: vaxis.Style) void {
    if (start >= end) return;

    var col = start;
    var iter = ctx.graphemeIterator(self.text);
    while (iter.next()) |entry| {
        if (col >= end) break;
        const grapheme = entry.bytes(self.text);
        const width: u8 = @intCast(ctx.stringWidth(grapheme));
        if (width == 0 or col + width > end) break;
        const byte_index: usize = @intFromPtr(grapheme.ptr) - @intFromPtr(self.text.ptr);
        surface.writeCell(col, 0, .{
            .char = .{ .grapheme = grapheme, .width = width },
            .style = if (self.isMatch(byte_index)) match_style else base_style,
        });
        col += width;
    }
}

fn isMatch(self: Row, byte_index: usize) bool {
    for (self.match_indexes) |index| {
        if (index == byte_index) return true;
        if (index > byte_index) return false;
    }
    return false;
}

fn cursorMarker(current: bool) []const u8 {
    return if (current) ">" else " ";
}

fn markMarker(marked: bool) []const u8 {
    return if (marked) ":" else " ";
}

fn gitMarker(status: GitStatus) []const u8 {
    return switch (status) {
        .none => " ",
        .modified => "M",
        .added => "A",
        .untracked => "?",
        .deleted => "D",
        .renamed => "R",
    };
}