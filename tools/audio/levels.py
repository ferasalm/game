"""Loudness table for the sound effects: reads the audio of a Godot movie capture (.avi, PCM) made by
tools/audio/measure_levels.gd plus its printed SLOT lines, and prints peak/RMS per sound id after its volume_db.
Run: python tools/audio/levels.py capture.avi slots.txt [--wav file.wav ...]
"""
import json
import struct
import sys
import wave
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[2]
SFX = "res://assets/audio/sfx/"
FLOOR = -120.0


def avi_audio(path: str) -> tuple[np.ndarray, int]:
    """Concatenates the 01wb chunks of a Godot-written AVI; returns (mono float samples, rate)."""
    data = Path(path).read_bytes()
    fmt = data.find(b"strf", data.find(b"auds"))
    channels, rate = struct.unpack_from("<HI", data, fmt + 8 + 2)
    chunks, pos = [], data.find(b"movi") + 4
    while pos + 8 <= len(data):
        tag, size = data[pos:pos + 4], struct.unpack_from("<I", data, pos + 4)[0]
        if tag == b"01wb":
            chunks.append(data[pos + 8:pos + 8 + size])
        elif tag == b"idx1":
            break
        pos += 8 + size + (size & 1)
    pcm = np.frombuffer(b"".join(chunks), dtype="<i2").astype(np.float64) / 32768.0
    return pcm.reshape(-1, channels).mean(axis=1), rate


def db(x: float) -> float:
    return 20 * np.log10(x) if x > 1e-6 else FLOOR


def measure(samples: np.ndarray) -> tuple[float, float]:
    """(peak dBFS, RMS dBFS over the active part: samples above -30 dB of the peak)."""
    peak = float(np.max(np.abs(samples)))
    live = samples[np.abs(samples) > peak * 10 ** (-30 / 20)]
    return db(peak), db(float(np.sqrt(np.mean(live ** 2))))


def wav_samples(path: Path) -> np.ndarray:
    with wave.open(str(path), "rb") as w:
        raw = np.frombuffer(w.readframes(w.getnframes()), dtype="<i2").astype(np.float64) / 32768.0
        return raw.reshape(-1, w.getnchannels()).mean(axis=1)


def main() -> None:
    avi, slots_file = sys.argv[1], sys.argv[2]
    samples, rate = avi_audio(avi)
    file_level: dict[str, tuple[float, float]] = {}
    for line in Path(slots_file).read_text().splitlines():
        if line.startswith("SLOT "):
            _, path, start, secs = line.split()
            a, b = max(int((float(start) - 0.02) * rate), 0), int((float(start) + float(secs) + 0.25) * rate)
            file_level[path.removeprefix(SFX)] = measure(samples[a:b])
    sounds = json.loads((ROOT / "content/audio/sounds.json").read_text())["items"]
    rows = []
    for s in sounds:
        peaks = [file_level[f][0] + s["volume_db"] for f in s["files"] if f in file_level]
        rmss = [file_level[f][1] + s["volume_db"] for f in s["files"] if f in file_level]
        if rmss:
            rows.append((s["id"], s["volume_db"], max(peaks), max(rmss)))
    for extra in sys.argv[3:]:
        if extra != "--wav":
            p, r = measure(wav_samples(Path(extra)))
            print(f"{extra}: peak {p:.1f} rms {r:.1f} dBFS (before volume_db)")
    print(f"{'id':22}{'vol_db':>8}{'peak':>8}{'rms':>8}")
    for row in rows:
        print(f"{row[0]:22}{row[1]:8.1f}{row[2]:8.1f}{row[3]:8.1f}")
    vfx = [r[3] for r in rows if r[0].startswith("vfx_") and r[0] != "vfx_arc_all"]
    print(f"median rms of the other vfx_*: {np.median(vfx):.1f}")


if __name__ == "__main__":
    main()
