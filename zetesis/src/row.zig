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
};

text: []const u8,
index: usize,
cursor: *const u32,
marked: bool = false,
git_status: GitStatus = .none,
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

    self.writeCell(surface, 0, cursorMarker(self.isCurrent()), marker_style);
    if (max.width > 1) self.writeCell(surface, 1, markMarker(self.marked), marker_style);
    if (max.width > 2) self.writeCell(surface, max.width - 1, gitMarker(self.git_status), git_style);

    const text_start: u16 = if (max.width > 2) 2 else max.width;
    const text_end: u16 = if (max.width > 3) max.width - 1 else text_start;

    var col = text_start;
    var iter = ctx.graphemeIterator(self.text);
    while (iter.next()) |entry| {
        if (col >= text_end) break;
        const grapheme = entry.bytes(self.text);
        const width: u8 = @intCast(ctx.stringWidth(grapheme));
        if (width == 0 or col + width > text_end) break;
        surface.writeCell(col, 0, .{
            .char = .{ .grapheme = grapheme, .width = width },
            .style = base_style,
        });
        col += width;
    }

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
