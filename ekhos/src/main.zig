const std = @import("std");
const renderer = @import("renderer.zig");

pub fn main(init: std.process.Init) !void {
    try renderer.renderAll(init);
}
