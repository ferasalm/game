#!/usr/bin/env python3
"""Helper for flicker_probe: computes heat map, masks rain, and saves flicker_walk.gif."""
import os
import sys
import numpy as np
from PIL import Image

INBOX_DIRS = [
    os.path.abspath("inbox"),
    "C:/dev/game/inbox"
]

def ensure_dirs():
    for d in INBOX_DIRS:
        os.makedirs(d, exist_ok=True)

def process_frames(frames_dir: str, is_before: bool = False):
    ensure_dirs()
    frame_files = sorted([f for f in os.listdir(frames_dir) if f.startswith("frame_") and f.endswith(".png")])
    if not frame_files:
        print("No frames found in", frames_dir)
        return 0.0

    imgs = [Image.open(os.path.join(frames_dir, f)).convert("RGB") for f in frame_files]
    arrs = [np.array(im, dtype=np.float32) for im in imgs]
    n_frames = len(arrs)
    h, w, _ = arrs[0].shape

    # Luminance for all frames: (N, H, W)
    lums = np.stack([0.2126 * a[:, :, 0] + 0.7152 * a[:, :, 1] + 0.0722 * a[:, :, 2] for a in arrs], axis=0)

    # Detect rain streaks: isolated transient spikes across time (1-2 frames)
    rain_mask = np.zeros((n_frames - 1, h, w), dtype=bool)
    for t in range(1, n_frames - 1):
        d_prev = lums[t] - lums[t - 1]
        d_next = lums[t + 1] - lums[t]
        spike = (d_prev > 3.0) & (d_next < -2.0)
        rain_mask[t - 1] |= spike
        rain_mask[t] |= spike
    for t in range(1, n_frames - 2):
        d1 = lums[t] - lums[t - 1]
        d2 = lums[t + 2] - lums[t + 1]
        spike2 = (d1 > 3.0) & (d2 < -2.0)
        rain_mask[t - 1] |= spike2
        rain_mask[t] |= spike2
        rain_mask[t + 1] |= spike2

    # Sum of frame-to-frame changes
    diffs = np.abs(lums[1:] - lums[:-1])

    # For heatmap: sum over all frames
    total_change = np.sum(diffs, axis=0)
    
    # Save GIF (640 wide)
    gif_frames = [im.resize((640, int(h * 640 / w)), Image.Resampling.BILINEAR) for im in imgs]
    for d in INBOX_DIRS:
        gif_path = os.path.join(d, "flicker_walk.gif")
        gif_frames[0].save(
            gif_path,
            save_all=True,
            append_images=gif_frames[1:],
            duration=33,
            loop=0
        )
        print("Saved", gif_path)

    # Compute heatmap over frame 0
    # Normalize change (ignore top 0.5% extreme outliers for contrast)
    vmax = np.percentile(total_change, 99.5)
    if vmax <= 0:
        vmax = 1.0
    norm = np.clip(total_change / vmax, 0.0, 1.0)

    # Turbo/Inferno-like heat ramp
    heat_r = np.clip(norm * 2.5, 0.0, 1.0)
    heat_g = np.clip((norm - 0.3) * 2.0, 0.0, 1.0)
    heat_b = np.clip((norm - 0.7) * 3.3, 0.0, 1.0)
    heat_rgb = np.stack([heat_r * 255, heat_g * 255, heat_b * 255], axis=-1)

    f0 = arrs[0]
    # Blend: where heat is low, keep frame 0; where heat is high, show heatmap
    alpha = np.clip(norm * 1.8, 0.0, 0.85)[:, :, None]
    blended = (f0 * (1.0 - alpha) + heat_rgb * alpha).astype(np.uint8)
    heat_img = Image.fromarray(blended)

    heat_name = "flicker_heat_before.png" if is_before else "flicker_heat.png"
    for d in INBOX_DIRS:
        heat_path = os.path.join(d, heat_name)
        heat_img.save(heat_path)
        print("Saved", heat_path)

    # Calculate FLICKER on floor region (bottom 40% of screen)
    # Mask rain streaks
    start_y = int(h * 0.6)
    floor_diffs = diffs[:, start_y:, :]
    floor_rain = rain_mask[:, start_y:, :]

    # Party mask: player walks around center x ~ 350..650
    # We measure on floor region excluding rain
    valid_mask = ~floor_rain
    if np.any(valid_mask):
        floor_flicker = floor_diffs[valid_mask].mean() / 255.0
    else:
        floor_flicker = floor_diffs.mean() / 255.0

    print(f"FLICKER_METRIC: {floor_flicker:.6f}")
    return floor_flicker

if __name__ == "__main__":
    is_bef = "--before" in sys.argv
    path = sys.argv[1] if len(sys.argv) > 1 and not sys.argv[1].startswith("--") else ".check/frames"
    process_frames(path, is_bef)
