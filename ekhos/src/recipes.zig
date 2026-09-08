const std = @import("std");

pub const sample_rate: u32 = 48_000;

pub const Cue = enum {
    chime,
    sparkle,
    droplet,
    bloom,
    whisper,
    tick,
    press,
    release,
    toggle,
    success,
    error_cue,
    page,
    loading,
    ready,
    pulse,
    scan,
    arrival,
};

pub const all = [_]Cue{
    .chime,   .sparkle, .droplet,   .bloom, .whisper, .tick,  .press, .release,
    .toggle,  .success, .error_cue, .page,  .loading, .ready, .pulse, .scan,
    .arrival,
};

const Waveform = enum { sine, triangle };
const Filter = enum { lowpass, bandpass };

pub fn filename(cue: Cue) []const u8 {
    return switch (cue) {
        .chime => "chime.wav",
        .sparkle => "sparkle.wav",
        .droplet => "droplet.wav",
        .bloom => "bloom.wav",
        .whisper => "whisper.wav",
        .tick => "tick.wav",
        .press => "press.wav",
        .release => "release.wav",
        .toggle => "toggle.wav",
        .success => "success.wav",
        .error_cue => "error.wav",
        .page => "page.wav",
        .loading => "loading.wav",
        .ready => "ready.wav",
        .pulse => "pulse.wav",
        .scan => "scan.wav",
        .arrival => "arrival.wav",
    };
}

pub fn duration(cue: Cue) f64 {
    return switch (cue) {
        .chime => 0.5,
        .sparkle => 0.4,
        .droplet => 0.35,
        .bloom => 0.7,
        .whisper => 0.35,
        .tick, .press => 0.06,
        .release => 0.12,
        .toggle => 0.1,
        .success => 0.4,
        .error_cue => 0.3,
        .page => 0.2,
        .loading => 0.45,
        .ready => 0.5,
        .pulse => 0.2,
        .scan => 0.3,
        .arrival => 0.75,
    };
}

pub fn render(cue: Cue, samples: []f64) void {
    switch (cue) {
        .chime => renderChime(samples),
        .sparkle => renderSparkle(samples),
        .droplet => renderDroplet(samples),
        .bloom => renderBloom(samples),
        .whisper => renderWhisper(samples),
        .tick => renderTick(samples),
        .press => renderPress(samples),
        .release => renderRelease(samples),
        .toggle => renderToggle(samples),
        .success => renderSuccess(samples),
        .error_cue => renderError(samples),
        .page => renderPage(samples),
        .loading => renderLoading(samples),
        .ready => renderReady(samples),
        .pulse => renderPulse(samples),
        .scan => renderScan(samples),
        .arrival => renderArrival(samples),
    }
}

fn renderChime(samples: []f64) void {
    tone(samples, .sine, 1046.5, null, 0, 0.006, 0.22, 0.09, 0.5);
    tone(samples, .sine, 1568, null, 0.09, 0.006, 0.26, 0.08, 0.5);
    shimmer(samples, 0.12, 0.25, 0.18, 4000);
}

fn renderSparkle(samples: []f64) void {
    tone(samples, .sine, 1760, null, 0, 0.003, 0.09, 0.045, 0.5);
    tone(samples, .sine, 2217, null, 0.045, 0.003, 0.09, 0.04, 0.5);
    tone(samples, .sine, 2637, null, 0.09, 0.003, 0.1, 0.038, 0.5);
    tone(samples, .sine, 3520, null, 0.135, 0.003, 0.12, 0.032, 0.5);
    shimmer(samples, 0.07, 0.35, 0.22, 6000);
}

fn renderDroplet(samples: []f64) void {
    tone(samples, .sine, 1200, 550, 0, 0.004, 0.2, 0.075, 0.55);
    shimmer(samples, 0.09, 0.2, 0.15, 3000);
}

fn renderBloom(samples: []f64) void {
    tone(samples, .sine, 528, null, 0, 0.06, 0.32, 0.06, 0.5);
    tone(samples, .sine, 528, null, 0, 0.06, 0.34, 0.05, 0.5);
    shimmer(samples, 0.15, 0.2, 0.12, 2500);
}

fn renderWhisper(samples: []f64) void {
    noise(samples, .lowpass, 1600, 0.7, 0, 0.025, 0.13, 0.04, 0.48);
    tone(samples, .sine, 880, 660, 0.01, 0.012, 0.14, 0.025, 0.48);
}

fn renderTick(samples: []f64) void {
    noise(samples, .bandpass, 5400, 1.8, 0, 0.001, 0.018, 0.14, 0.4);
    tone(samples, .sine, 2600, null, 0, 0.001, 0.012, 0.018, 0.4);
}

fn renderPress(samples: []f64) void {
    noise(samples, .bandpass, 1700, 1.4, 0, 0.001, 0.02, 0.13, 0.4);
}

fn renderRelease(samples: []f64) void {
    noise(samples, .bandpass, 4600, 1.8, 0, 0.001, 0.016, 0.12, 0.4);
    tone(samples, .sine, 3200, null, 0.006, 0.001, 0.05, 0.02, 0.4);
}

fn renderToggle(samples: []f64) void {
    noise(samples, .bandpass, 2200, 1.6, 0, 0.001, 0.016, 0.12, 0.4);
    noise(samples, .bandpass, 3800, 1.6, 0.024, 0.001, 0.02, 0.1, 0.4);
}

fn renderSuccess(samples: []f64) void {
    tone(samples, .sine, 880, null, 0, 0.004, 0.09, 0.06, 0.5);
    tone(samples, .sine, 1108.73, null, 0.06, 0.004, 0.1, 0.06, 0.5);
    tone(samples, .sine, 1318.51, null, 0.12, 0.004, 0.18, 0.07, 0.5);
    shimmer(samples, 0.1, 0.22, 0.16, 4500);
}

fn renderError(samples: []f64) void {
    noise(samples, .bandpass, 850, 1.1, 0, 0.001, 0.035, 0.13, 0.42);
    tone(samples, .triangle, 440, null, 0.025, 0.004, 0.09, 0.045, 0.42);
    tone(samples, .triangle, 349.23, null, 0.1, 0.004, 0.14, 0.04, 0.42);
}

fn renderPage(samples: []f64) void {
    noise(samples, .lowpass, 1800, 0.7, 0, 0.006, 0.08, 0.11, 0.38);
    noise(samples, .bandpass, 4200, 1.2, 0.04, 0.004, 0.065, 0.08, 0.38);
    tone(samples, .sine, 2400, null, 0.075, 0.002, 0.045, 0.02, 0.38);
}

fn renderLoading(samples: []f64) void {
    noise(samples, .lowpass, 1400, 0.6, 0, 0.035, 0.14, 0.035, 0.42);
    tone(samples, .sine, 420, 630, 0, 0.025, 0.18, 0.05, 0.42);
    shimmer(samples, 0.11, 0.18, 0.12, 2800);
}

fn renderReady(samples: []f64) void {
    noise(samples, .bandpass, 3600, 1.8, 0, 0.001, 0.02, 0.11, 0.48);
    tone(samples, .triangle, 330, 660, 0.012, 0.004, 0.16, 0.055, 0.48);
    tone(samples, .sine, 990, null, 0.13, 0.004, 0.22, 0.06, 0.48);
    shimmer(samples, 0.1, 0.16, 0.1, 4200);
}

fn renderPulse(samples: []f64) void {
    noise(samples, .bandpass, 2600, 2.4, 0, 0.001, 0.022, 0.08, 0.42);
    tone(samples, .triangle, 620, 1240, 0, 0.002, 0.085, 0.055, 0.42);
}

fn renderScan(samples: []f64) void {
    tone(samples, .sine, 740, null, 0, 0.002, 0.055, 0.05, 0.4);
    tone(samples, .sine, 1110, null, 0.045, 0.002, 0.055, 0.045, 0.4);
    tone(samples, .sine, 1665, null, 0.09, 0.002, 0.07, 0.04, 0.4);
    shimmer(samples, 0.065, 0.16, 0.1, 4200);
}

fn renderArrival(samples: []f64) void {
    noise(samples, .lowpass, 900, 0.8, 0, 0.05, 0.24, 0.035, 0.44);
    tone(samples, .sine, 220, 440, 0, 0.04, 0.32, 0.055, 0.44);
    tone(samples, .sine, 659.25, null, 0.12, 0.045, 0.32, 0.04, 0.44);
    tone(samples, .sine, 987.77, null, 0.19, 0.045, 0.34, 0.032, 0.44);
    shimmer(samples, 0.16, 0.28, 0.18, 3200);
}

fn tone(
    samples: []f64,
    waveform: Waveform,
    frequency: f64,
    glide_to: ?f64,
    offset: f64,
    attack: f64,
    decay: f64,
    peak: f64,
    gain: f64,
) void {
    const rate = @as(f64, @floatFromInt(sample_rate));
    const glide_time = attack + decay;
    const end_frequency = glide_to orelse frequency;

    for (samples, 0..) |*sample, index| {
        const elapsed = @as(f64, @floatFromInt(index)) / rate - offset;
        const envelope = envelopeAt(elapsed, attack, decay, peak) orelse continue;
        const glide_elapsed = @min(@max(elapsed, 0), glide_time);
        const slope = (end_frequency - frequency) / glide_time;
        const phase = frequency * glide_elapsed + 0.5 * slope * glide_elapsed * glide_elapsed;
        const cycles = if (glide_to == null) frequency * elapsed else phase;
        const wave = switch (waveform) {
            .sine => @sin(2 * std.math.pi * cycles),
            .triangle => std.math.asin(@sin(2 * std.math.pi * cycles)) * (2.0 / std.math.pi),
        };
        sample.* += wave * envelope * gain;
    }
}

fn noise(
    samples: []f64,
    filter: Filter,
    frequency: f64,
    q: f64,
    offset: f64,
    attack: f64,
    decay: f64,
    peak: f64,
    gain: f64,
) void {
    const rate = @as(f64, @floatFromInt(sample_rate));
    const low_alpha = filterAlpha(@max(20, frequency / q), rate);
    const high_alpha = filterAlpha(@min(rate / 2 - 1, frequency * q), rate);
    var random_state: u32 = 0x9e37_79b9 ^ @as(u32, @intFromFloat(frequency));
    var low_state: f64 = 0;
    var band_state: f64 = 0;

    for (samples, 0..) |*sample, index| {
        const raw = nextNoise(&random_state);
        low_state += low_alpha * (raw - low_state);
        const highpassed = raw - low_state;
        band_state += high_alpha * (highpassed - band_state);
        const filtered = if (filter == .lowpass) low_state else band_state;
        const elapsed = @as(f64, @floatFromInt(index)) / rate - offset;
        const envelope = envelopeAt(elapsed, attack, decay, peak) orelse continue;
        sample.* += filtered * envelope * gain;
    }
}

fn shimmer(samples: []f64, delay: f64, feedback: f64, wet: f64, lowpass: f64) void {
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
