const std = @import("std");
const recipes = @import("recipes.zig");
const wav = @import("wav.zig");

pub fn renderAll(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    for (recipes.all) |cue| {
        const sample_count = @as(usize, @intFromFloat(recipes.duration(cue) * recipes.sample_rate));
        const samples = try allocator.alloc(f64, sample_count);
        @memset(samples, 0);
        recipes.render(cue, samples);
        try wav.write(init.io, recipes.filename(cue), samples);
    }
}
