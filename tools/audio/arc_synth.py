"""Synthesizes the Arc Discharge sound (vfx_arc_all): 3 seeded variations as 44.1 kHz mono 16-bit WAV.

Layers: soft-attack crackle (band-passed noise bursts with random micro-gaps), a warm low hum with a few
harmonics, and a short low-level bright zap. Everything is low-passed so nothing harsh sits at 2-5 kHz, then
the peak is set to PEAK_DBFS. Run: python tools/audio/arc_synth.py [out_dir]
"""
import sys
import wave
from pathlib import Path

import numpy as np

RATE = 44100
PEAK_DBFS = -3.0
VARIANTS = {1: (0.62, 71.0), 2: (0.74, 88.0), 3: (0.86, 104.0)}  # seed: (seconds, hum Hz)
OUT_DIR = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx" / "qarnaw"


def band(x: np.ndarray, lo: float, hi: float, slope: float = 4.0) -> np.ndarray:
    """Smooth FFT band-pass (lo or hi of 0 means open on that side)."""
    spec = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1.0 / RATE)
    mask = np.ones_like(f)
    if lo > 0:
        mask *= 1.0 / (1.0 + (lo / np.maximum(f, 1e-3)) ** (2 * slope))
    if hi > 0:
        mask *= 1.0 / (1.0 + (f / hi) ** (2 * slope))
    return np.fft.irfft(spec * mask, len(x))


def crackle(rng: np.random.Generator, n: int) -> np.ndarray:
    t = np.arange(n) / RATE
    out = np.zeros(n)
    time = 0.0
    dur = n / RATE
    while time < dur:
        rate = 70.0 * np.exp(-1.8 * time / dur) + 12.0  # bursts per second, thinning out
        time += rng.exponential(1.0 / rate)
        start = int(time * RATE)
        length = int(rng.uniform(0.002, 0.009) * RATE)
        if start + length >= n:
            break
        env = np.sin(np.linspace(0, np.pi, length)) ** 2 * np.exp(-np.linspace(0, 3, length))
        out[start:start + length] += rng.normal(0, 1, length) * env * rng.uniform(0.3, 1.0)
    gate = np.ones(n)  # micro-gaps: random 3-14 ms holes
    pos = 0
    while pos < n:
        pos += int(rng.uniform(0.012, 0.045) * RATE)
        hole = int(rng.uniform(0.003, 0.014) * RATE)
        gate[pos:pos + hole] *= 0.15
        pos += hole
    gate = band(gate, 0, 400.0, 1.0)
    out = band(out * np.clip(gate, 0, 1), 650.0, 1900.0)
    return out / (np.max(np.abs(out)) + 1e-9) * np.exp(-2.4 * t / (n / RATE))


def hum(rng: np.random.Generator, n: int, base: float) -> np.ndarray:
    t = np.arange(n) / RATE
    out = np.zeros(n)
    for k, amp in ((1, 1.0), (2, 0.55), (3, 0.38), (4, 0.18), (6, 0.1)):
        out += amp * np.sin(2 * np.pi * base * k * t + rng.uniform(0, 6.28))
    out *= 1.0 + 0.25 * np.sin(2 * np.pi * rng.uniform(7, 13) * t)  # slow wobble, alive not static
    attack = np.minimum(t / 0.02, 1.0)
    return out * attack * np.exp(-3.0 * t / (n / RATE)) / 2.2


def zap(n: int) -> np.ndarray:
    length = int(0.07 * RATE)
    t = np.arange(length) / RATE
    sweep = 1500.0 * np.exp(-t * 28.0) + 350.0
    phase = 2 * np.pi * np.cumsum(sweep) / RATE
    env = np.minimum(t / 0.004, 1.0) * np.exp(-t * 55.0)
    out = np.zeros(n)
    out[:length] = np.sin(phase) * env
    return out


def synth(seed: int) -> np.ndarray:
    seconds, base = VARIANTS[seed]
    rng = np.random.default_rng(seed)
    n = int(seconds * RATE)
    mix = 1.0 * crackle(rng, n) + 0.4 * hum(rng, n, base) + 0.28 * zap(n)
    mix = band(mix, 45.0, 3800.0)
    fade = int(0.12 * RATE)
    mix[-fade:] *= np.cos(np.linspace(0, np.pi / 2, fade)) ** 2  # smooth tail, no click
    mix[:8] *= np.linspace(0, 1, 8)
    mix = np.tanh(mix * 1.3)
    return mix / np.max(np.abs(mix)) * 10 ** (PEAK_DBFS / 20)


def write_wav(path: Path, data: np.ndarray) -> None:
    pcm = np.round(np.clip(data, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())


def main() -> None:
    out_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else OUT_DIR
    out_dir.mkdir(parents=True, exist_ok=True)
    for seed in VARIANTS:
        data = synth(seed)
        write_wav(out_dir / f"arc_discharge_{seed:02d}.wav", data)
        rms = 20 * np.log10(np.sqrt(np.mean(data ** 2)))
        print(f"arc_discharge_{seed:02d}.wav  {len(data) / RATE:.2f} s  peak {20 * np.log10(np.max(np.abs(data))):.1f}  rms {rms:.1f} dBFS")


if __name__ == "__main__":
    main()
