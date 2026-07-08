#!/usr/bin/env python3
"""Generate ambient audio loops for HEAL.

Each track is ~30s, loops cleanly. Output as MP3 to a target directory.
Designed to be small (loops, not full songs).

Tracks:
  - rain: filtered white noise with low-frequency emphasis
  - fire: low rumble with random "pop" transients
  - wind: pink noise with slow LFO sweep
  - ocean: amplitude-modulated low-frequency noise (waves)
  - forest: light noise with sparse bird-chirp tones
  - night: very quiet noise with cricket-like chirps
"""
import os, struct, math, random
import wave
import io

SAMPLE_RATE = 22050
DURATION = 30  # seconds
OUT_DIR = "/workspace/.mavis-cache/heal-ambient"

os.makedirs(OUT_DIR, exist_ok=True)
random.seed(42)


def write_wav(path, samples, rate=SAMPLE_RATE):
    """Write mono 16-bit PCM WAV."""
    n = len(samples)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        for s in samples:
            v = max(-1.0, min(1.0, s))
            w.writeframes(struct.pack('<h', int(v * 32767)))


def smooth_loop(samples):
    """Crossfade the end into the start so loops don't click."""
    n = len(samples)
    fade = int(SAMPLE_RATE * 0.5)  # 500ms crossfade
    for i in range(fade):
        a = i / fade
        end_i = n - fade + i
        mixed = samples[end_i] * (1 - a) + samples[i] * a
        samples[end_i] = mixed
        samples[i] = mixed
    return samples


# ── Rain: filtered noise with a touch of low-frequency body
def gen_rain():
    n = SAMPLE_RATE * DURATION
    out = [0.0] * n
    # Base noise
    for i in range(n):
        out[i] = random.uniform(-1, 1) * 0.5
    # Low-pass: simple moving average
    smooth = [0.0] * n
    win = 200
    for i in range(n):
        s = 0.0
        for k in range(-win, win + 1):
            j = max(0, min(n - 1, i + k))
            s += out[j]
        smooth[i] = s / (2 * win + 1)
    # Add high-frequency hiss (drizzle on top)
    for i in range(n):
        smooth[i] = smooth[i] * 0.7 + random.uniform(-0.4, 0.4) * 0.3
    # Normalize
    peak = max(abs(s) for s in smooth)
    if peak > 0:
        smooth = [s / peak * 0.7 for s in smooth]
    return smooth_loop(smooth)


# ── Fire: low rumble + random pops
def gen_fire():
    n = SAMPLE_RATE * DURATION
    out = [0.0] * n
    # Base low rumble
    for i in range(n):
        t = i / SAMPLE_RATE
        out[i] = (
            math.sin(2 * math.pi * 60 * t) * 0.2 +
            math.sin(2 * math.pi * 80 * t) * 0.15 +
            random.uniform(-0.2, 0.2) * 0.4
        )
    # Random pop transients
    for _ in range(int(DURATION * 4)):
        pos = random.randint(0, n - 1)
        amp = random.uniform(0.2, 0.6)
        decay = random.randint(SAMPLE_RATE // 20, SAMPLE_RATE // 4)
        for k in range(decay):
            if pos + k < n:
                out[pos + k] += amp * math.exp(-k / decay * 4) * random.choice([-1, 1])
    # Low-pass
    win = 100
    for i in range(n):
        s = 0.0
        for k in range(-win, win + 1):
            j = max(0, min(n - 1, i + k))
            s += out[j]
        out[i] = s / (2 * win + 1)
    peak = max(abs(s) for s in out)
    if peak > 0:
        out = [s / peak * 0.7 for s in out]
    return smooth_loop(out)


# ── Wind: pink noise + slow LFO
def gen_wind():
    n = SAMPLE_RATE * DURATION
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        # Pink-ish noise via Voss-McCartney approximation
        n1 = random.uniform(-1, 1)
        n2 = random.uniform(-1, 1)
        # Slow LFO modulating amplitude
        lfo = 0.5 + 0.5 * math.sin(2 * math.pi * 0.13 * t)
        # Slow LFO 2
        lfo2 = 0.5 + 0.5 * math.sin(2 * math.pi * 0.07 * t + 1.0)
        out[i] = (n1 * 0.3 + n2 * 0.2) * lfo * lfo2
    # Low-pass
    win = 400
    smooth = [0.0] * n
    for i in range(n):
        s = 0.0
        for k in range(-win, win + 1):
            j = max(0, min(n - 1, i + k))
            s += out[j]
        smooth[i] = s / (2 * win + 1)
    peak = max(abs(s) for s in smooth)
    if peak > 0:
        smooth = [s / peak * 0.7 for s in smooth]
    return smooth_loop(smooth)


# ── Ocean: amplitude-modulated low noise (waves)
def gen_ocean():
    n = SAMPLE_RATE * DURATION
    out = [0.0] * n
    for i in range(n):
        t = i / SAMPLE_RATE
        # Wave envelope: ~6s period
        wave_env = 0.5 + 0.5 * (math.sin(2 * math.pi * 0.18 * t) ** 3)
        # Add swell
        swell = 0.5 + 0.5 * math.sin(2 * math.pi * 0.05 * t + 0.3)
        out[i] = random.uniform(-1, 1) * 0.4 * wave_env * swell
    # Low-pass
    win = 300
    smooth = [0.0] * n
    for i in range(n):
        s = 0.0
        for k in range(-win, win + 1):
            j = max(0, min(n - 1, i + k))
            s += out[j]
        smooth[i] = s / (2 * win + 1)
    peak = max(abs(s) for s in smooth)
    if peak > 0:
        smooth = [s / peak * 0.7 for s in smooth]
    return smooth_loop(smooth)


# ── Forest: light noise with sparse bird-chirps
def gen_forest():
    n = SAMPLE_RATE * DURATION
    out = [0.0] * n
    for i in range(n):
        out[i] = random.uniform(-0.2, 0.2)
    # Bird chirps: 8 per minute
    for _ in range(int(DURATION / 7.5)):
        pos = random.randint(SAMPLE_RATE // 2, n - SAMPLE_RATE)
        duration = random.randint(SAMPLE_RATE // 30, SAMPLE_RATE // 8)
        base_freq = random.uniform(1800, 3500)
        for k in range(duration):
            t = k / SAMPLE_RATE
            freq = base_freq + 200 * math.sin(2 * math.pi * 8 * t)
            env = math.sin(math.pi * k / duration)
            out[pos + k] += 0.4 * env * math.sin(2 * math.pi * freq * t)
    # Small water trickle
    for _ in range(2):
        pos = random.randint(0, n - SAMPLE_RATE * 2)
        for k in range(SAMPLE_RATE * 2):
            out[pos + k] += random.uniform(-0.1, 0.1) * 0.3
    peak = max(abs(s) for s in out)
    if peak > 0:
        out = [s / peak * 0.7 for s in out]
    return smooth_loop(out)


# ── Night crickets: quiet with sparse chirps
def gen_night():
    n = SAMPLE_RATE * DURATION
    out = [0.0] * n
    # Very low base noise
    for i in range(n):
        out[i] = random.uniform(-0.1, 0.1)
    # Cricket chirps: 4-5kHz, ~50ms bursts
    for _ in range(int(DURATION * 6)):
        pos = random.randint(0, n - SAMPLE_RATE // 4)
        dur = random.randint(SAMPLE_RATE // 40, SAMPLE_RATE // 15)
        for k in range(dur):
            t = k / SAMPLE_RATE
            freq = random.uniform(4000, 5500)
            env = math.sin(math.pi * k / dur) ** 2
            out[pos + k] += 0.5 * env * math.sin(2 * math.pi * freq * t)
    peak = max(abs(s) for s in out)
    if peak > 0:
        out = [s / peak * 0.6 for s in out]
    return smooth_loop(out)


# Generate all
generators = {
    'rain-loop': gen_rain,
    'fire-loop': gen_fire,
    'wind-loop': gen_wind,
    'ocean-loop': gen_ocean,
    'forest-loop': gen_forest,
    'night-loop': gen_night,
}

for name, fn in generators.items():
    print(f'Generating {name}...')
    samples = fn()
    out = os.path.join(OUT_DIR, f'{name}.wav')
    write_wav(out, samples)
    size = os.path.getsize(out)
    print(f'  -> {out} ({size:,} bytes, {len(samples) / SAMPLE_RATE:.1f}s)')

print('Done.')