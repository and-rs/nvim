const std = @import("std");
const recipes = @import("recipes.zig");
const wav = @import("wav.zig");

const target_rms: f64 = 0.01;
const peak_ceiling: f64 = 0.2;

pub fn renderAll(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    for (recipes.all) |cue| {
        const sample_count = @as(usize, @intFromFloat(recipes.duration(cue) * recipes.sample_rate));
        const samples = try allocator.alloc(f64, sample_count);
        @memset(samples, 0);
        recipes.render(cue, samples);
        normalize(samples);
        try wav.write(init.io, recipes.filename(cue), samples);
    }
}

fn normalize(samples: []f64) void {
    var energy: f64 = 0;
    var peak: f64 = 0;

    for (samples) |sample| {
        energy += sample * sample;
        peak = @max(peak, @abs(sample));
    }

    if (peak == 0) return;

    const rms = std.math.sqrt(energy / @as(f64, @floatFromInt(samples.len)));
    const gain = @min(target_rms / rms, peak_ceiling / peak);

    for (samples) |*sample| sample.* *= gain;
}
