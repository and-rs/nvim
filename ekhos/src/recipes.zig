const std = @import("std");

pub const sample_rate: u32 = 48_000;

pub const Cue = enum {
    scan,
    bloom,
    toggle,
    release,
};

pub const all = [_]Cue{ .scan, .bloom, .toggle, .release };

const Tone = struct {
    frequency: f64,
    offset: f64 = 0,
    attack: f64,
    decay: f64,
    peak: f64,
};

pub fn filename(cue: Cue) []const u8 {
    return switch (cue) {
        .scan => "scan.wav",
        .bloom => "bloom.wav",
        .toggle => "toggle.wav",
        .release => "release.wav",
    };
}

pub fn duration(cue: Cue) f64 {
    return switch (cue) {
        .scan => 0.42,
        .bloom => 0.7,
        .toggle => 0.2,
        .release => 0.25,
    };
}

pub fn render(cue: Cue, samples: []f64) void {
    switch (cue) {
        .scan => renderScan(samples),
        .bloom => renderBloom(samples),
        .toggle => renderToggle(samples),
        .release => renderRelease(samples),
    }
}

fn renderScan(samples: []f64) void {
    const notes = [_]Tone{
        .{ .frequency = 740, .attack = 0.002, .decay = 0.055, .peak = 0.05 },
        .{ .frequency = 1110, .offset = 0.045, .attack = 0.002, .decay = 0.055, .peak = 0.045 },
        .{ .frequency = 1665, .offset = 0.09, .attack = 0.002, .decay = 0.07, .peak = 0.04 },
    };
    for (notes) |note| addTone(samples, note, 0.4);
    applyShimmer(samples, 0.065, 0.16, 0.1, 4200);
}

fn renderBloom(samples: []f64) void {
    addTone(samples, .{ .frequency = 528, .attack = 0.06, .decay = 0.32, .peak = 0.06 }, 0.5);
    addTone(samples, .{ .frequency = 531.67, .attack = 0.06, .decay = 0.34, .peak = 0.05 }, 0.5);
    applyShimmer(samples, 0.15, 0.2, 0.12, 2500);
}

fn renderToggle(samples: []f64) void {
    addNoise(samples, 0, 0.001, 0.016, 0.12, 2200, 1.6, 0x3b2f_1f31, 0.4);
    addNoise(samples, 0.024, 0.001, 0.02, 0.1, 3800, 1.6, 0xa195_3d67, 0.4);
}

fn renderRelease(samples: []f64) void {
    addNoise(samples, 0, 0.001, 0.016, 0.12, 4600, 1.8, 0x7c8e_15a1, 0.4);
    addTone(samples, .{ .frequency = 3200, .offset = 0.006, .attack = 0.001, .decay = 0.05, .peak = 0.02 }, 0.4);
}

fn addTone(samples: []f64, tone: Tone, gain: f64) void {
    const rate = @as(f64, @floatFromInt(sample_rate));
    for (samples, 0..) |*sample, index| {
        const elapsed = @as(f64, @floatFromInt(index)) / rate - tone.offset;
        const envelope = envelopeAt(elapsed, tone.attack, tone.decay, tone.peak) orelse continue;
        sample.* += @sin(2 * std.math.pi * tone.frequency * elapsed) * envelope * gain;
    }
}

fn addNoise(
    samples: []f64,
    offset: f64,
    attack: f64,
    decay: f64,
    peak: f64,
    frequency: f64,
    q: f64,
    seed: u32,
    gain: f64,
) void {
    const rate = @as(f64, @floatFromInt(sample_rate));
    const low_alpha = filterAlpha(@max(20, frequency / q), rate);
    const high_alpha = filterAlpha(@min(rate / 2 - 1, frequency * q), rate);
    var random_state = seed;
    var low_state: f64 = 0;
    var band_state: f64 = 0;

    for (samples, 0..) |*sample, index| {
        const noise = nextNoise(&random_state);
        low_state += low_alpha * (noise - low_state);
        const highpassed = noise - low_state;
        band_state += high_alpha * (highpassed - band_state);

        const elapsed = @as(f64, @floatFromInt(index)) / rate - offset;
        const envelope = envelopeAt(elapsed, attack, decay, peak) orelse continue;
        sample.* += band_state * envelope * gain;
    }
}

fn applyShimmer(samples: []f64, delay: f64, feedback: f64, wet: f64, lowpass: f64) void {
    const rate = @as(f64, @floatFromInt(sample_rate));
    const delay_samples = @as(usize, @intFromFloat(delay * rate));
    var delay_line: [sample_rate / 5]f64 = @splat(0);
    var delay_index: usize = 0;
    var lowpass_state: f64 = 0;
    const lowpass_alpha = filterAlpha(lowpass, rate);

    for (samples) |*sample| {
        const delayed = delay_line[delay_index];
        lowpass_state += lowpass_alpha * (delayed - lowpass_state);
        sample.* += lowpass_state * wet;
        delay_line[delay_index] = sample.* + lowpass_state * feedback;
        delay_index = (delay_index + 1) % delay_samples;
    }
}

fn envelopeAt(elapsed: f64, attack: f64, decay: f64, peak: f64) ?f64 {
    if (elapsed < 0 or elapsed > attack + decay) return null;
    if (elapsed < attack) return 0.0001 * std.math.pow(f64, peak / 0.0001, elapsed / attack);
    return peak * std.math.pow(f64, 0.0001 / peak, (elapsed - attack) / decay);
}

fn filterAlpha(frequency: f64, rate: f64) f64 {
    return 1 - std.math.exp(-2 * std.math.pi * frequency / rate);
}

fn nextNoise(state: *u32) f64 {
    state.* = state.* *% 1_664_525 +% 1_013_904_223;
    return @as(f64, @floatFromInt(state.*)) / @as(f64, @floatFromInt(std.math.maxInt(u32))) * 2 - 1;
}
