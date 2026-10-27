"""Free recolour of a Rodin model texture from an approved front picture (route: .claude/skills/3d-model/SKILL.md).
Keeps the old texture's lightness detail (UV-aligned ink) and takes colour from the picture projected from the front;
texels the front cannot see get the median colour of front texels of the same height band, side and old lightness.
Run (after tools/art/recolour_bake.py bake): python tools/art/recolour.py <bake dir> <old.png> <picture> <out.png> [overlay.png]
"""
import os
import sys

import numpy as np
from PIL import Image

HEIGHT_BINS, LIGHT_BINS = 24, 3  # 1 band greys the coat's back and the hands; 6 leak strap green onto the back


def srgb_to_lab(rgb):
    c = rgb.astype(np.float64) / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    m = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]])
    xyz = c @ m.T / np.array([0.95047, 1.0, 1.08883])
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16.0 / 116.0)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], -1)


def lab_to_srgb(lab):
    fy = (lab[..., 0] + 16) / 116.0
    f = np.stack([fy + lab[..., 1] / 500.0, fy, fy - lab[..., 2] / 200.0], -1)
    xyz = np.where(f > 0.206893, f ** 3, (f - 16.0 / 116.0) / 7.787) * np.array([0.95047, 1.0, 1.08883])
    m = np.array([[3.2406, -1.5372, -0.4986], [-0.9689, 1.8758, 0.0415], [0.0557, -0.2040, 1.0570]])
    c = np.clip(xyz @ m.T, 0, 1)
    c = np.where(c > 0.0031308, 1.055 * c ** (1 / 2.4) - 0.055, 12.92 * c)
    return np.clip(np.round(c * 255), 0, 255).astype(np.uint8)


def box_blur(a, r):
    """Mean over a (2r+1)^2 window (edges clamp); a is HxW or HxWxC."""
    if r <= 0:
        return a.astype(np.float64)
    out = a.astype(np.float64)
    for axis in (0, 1):
        pad = [(0, 0)] * out.ndim; pad[axis] = (r + 1, r)
        c = np.cumsum(np.pad(out, pad, mode="edge"), axis=axis)
        hi = np.take(c, np.arange(2 * r + 1, c.shape[axis]), axis=axis)
        lo = np.take(c, np.arange(0, c.shape[axis] - 2 * r - 1), axis=axis)
        out = (hi - lo) / (2 * r + 1)
    return out


def figure_mask(pic, thresh=40.0, r=3):
    """Figure pixels: far from the border's background colour, opened by r to drop ink specks."""
    border = np.concatenate([pic[0], pic[-1], pic[:, 0], pic[:, -1]]).astype(np.float64)
    bg = np.median(border, axis=0)
    mask = np.linalg.norm(pic.astype(np.float64) - bg, axis=-1) > thresh
    eroded = box_blur(mask, r) > 0.999
    return box_blur(eroded, r) > 0.001


def fit_picture(mask, top_z):
    """Picture pixel = (ox + s * x, oz - s * z): head top and feet rows set the scale, torso columns the centre."""
    rows = np.where(mask.sum(1) > mask.shape[1] * 0.01)[0]
    top, bottom = rows[0], rows[-1]
    s = (bottom - top) / top_z
    torso = mask[int(top + 0.3 * (bottom - top)):int(top + 0.5 * (bottom - top))]
    ox = float(np.median(np.nonzero(torso)[1]))
    return s, ox, float(bottom)


def sample(img, px, py):
    """Nearest sample of img (HxW[xC]) at float pixel coords, clamped."""
    h, w = img.shape[:2]
    return img[np.clip(np.round(py).astype(int), 0, h - 1), np.clip(np.round(px).astype(int), 0, w - 1)]


def smoothstep(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0, 1)
    return t * t * (3 - 2 * t)


def front_weight(nrm, lit, inside):
    """How much the front picture may colour a texel: faces the camera (-Y), lit by the front sun, inside the figure."""
    litn = lit / max(float(np.percentile(lit, 99.5)), 1e-6)
    return smoothstep(0.25, 0.55, -nrm[..., 1]) * smoothstep(0.3, 0.6, litn) * inside


def group_median(ids, vals, n):
    """Per-id median of vals (N x C); NaN rows for ids with no samples."""
    out = np.full((n, vals.shape[1]), np.nan)
    order = np.argsort(ids, kind="stable")
    ids_s = ids[order]
    starts = np.searchsorted(ids_s, np.arange(n)); ends = np.searchsorted(ids_s, np.arange(n), side="right")
    for i in np.nonzero(ends > starts)[0]:
        out[i] = np.median(vals[order[starts[i]:ends[i]]], axis=0)
    return out


def fill_gaps(table):
    """Empty height bins (NaN rows) take the nearest filled bin above or below; all-empty stays NaN."""
    rows = np.nonzero(~np.isnan(table[:, 0]))[0]
    if len(rows) == 0:
        return table
    near = rows[np.abs(np.arange(len(table))[:, None] - rows[None, :]).argmin(1)]
    return table[near]


def fill_hidden(pos, light, target, train, top_z):
    """Target (HxWx3: shiftL, a, b) for every texel: per lightness band, the median of the training texels in each
    height bin, linearly blended between bin centres (no blocks); a band with no samples uses all bands."""
    hf = np.clip(pos[..., 2] / top_z * HEIGHT_BINS - 0.5, 0, HEIGHT_BINS - 1).ravel()
    h0 = np.floor(hf).astype(int); h1 = np.minimum(h0 + 1, HEIGHT_BINS - 1); t = (hf - h0)[:, None]
    lb = np.clip((light / 100.0 * LIGHT_BINS).astype(int), 0, LIGHT_BINS - 1).ravel()
    vals = target.reshape(-1, 3); tr = train.ravel()
    hz = np.clip((pos[..., 2] / top_z * HEIGHT_BINS).astype(int), 0, HEIGHT_BINS - 1).ravel()
    every = fill_gaps(group_median(hz[tr], vals[tr], HEIGHT_BINS))
    out = np.zeros_like(vals)
    for band in range(LIGHT_BINS):
        sel = tr & (lb == band)
        table = fill_gaps(group_median(hz[sel], vals[sel], HEIGHT_BINS)) if sel.sum() >= 50 else every
        table = np.where(np.isnan(table), every, table)
        rows = lb == band
        out[rows] = (1 - t[rows]) * table[h0[rows]] + t[rows] * table[h1[rows]]
    return np.nan_to_num(out).reshape(target.shape)


def recolour(old_rgb, pos, nrm, lit, pic_rgb, blur_ab=8, blur_l=24):
    """New sRGB texture (same size as old_rgb) and the front weight map."""
    top_z = float(pos[..., 2].max())
    mask = figure_mask(pic_rgb)
    s, ox, oz = fit_picture(mask, top_z)
    px, py = ox + s * pos[..., 0], oz - s * pos[..., 2]
    pic_lab = srgb_to_lab(pic_rgb)
    old_lab = srgb_to_lab(old_rgb)
    inside = sample(box_blur(mask, 3) > 0.999, px, py).astype(np.float64)  # 6 px lost the fingers
    weight = front_weight(nrm, lit, inside)
    # Lightness shift: low-frequency picture L minus low-frequency old L, both in picture space.
    seen = weight > 0.5
    acc = np.zeros(mask.shape); cnt = np.zeros(mask.shape)
    iy = np.clip(np.round(py[seen]).astype(int), 0, mask.shape[0] - 1)
    ix = np.clip(np.round(px[seen]).astype(int), 0, mask.shape[1] - 1)
    np.add.at(acc, (iy, ix), old_lab[..., 0][seen]); np.add.at(cnt, (iy, ix), 1)
    old_low = box_blur(acc, blur_l) / np.maximum(box_blur(cnt, blur_l), 1e-9)
    pic_low = box_blur(pic_lab[..., 0], blur_l)
    shift = sample(pic_low, px, py) - sample(old_low, px, py)
    ab = sample(box_blur(pic_lab[..., 1:], blur_ab), px, py)
    target = np.concatenate([shift[..., None], ab], -1)
    # Hidden texels are mostly the coat's back: learn from seen texels facing sideways (coat sides, sleeves, hair),
    # not from the open chest and straps that face the camera.
    oblique = (weight > 0.5) & (-nrm[..., 1] < 0.65)
    filled = fill_hidden(pos, old_lab[..., 0], target, oblique, top_z)
    w = weight[..., None]
    mix = w * target + (1 - w) * filled
    lab = np.stack([np.clip(old_lab[..., 0] + mix[..., 0], 0, 100), mix[..., 1], mix[..., 2]], -1)
    return lab_to_srgb(lab), weight, (s, ox, oz)


def mean_chroma(rgb):
    lab = srgb_to_lab(rgb)
    return float(np.hypot(lab[..., 1], lab[..., 2]).mean())


def main(argv):
    bake_dir, old_path, pic_path, out_path = argv[:4]
    pos = np.load(os.path.join(bake_dir, "pos.npy"))
    n = pos.shape[0]
    nrm = np.load(os.path.join(bake_dir, "nrm.npy")); lit = np.load(os.path.join(bake_dir, "lit.npy"))
    old = np.asarray(Image.open(old_path).convert("RGB").resize((n, n), Image.LANCZOS))
    pic = np.asarray(Image.open(pic_path).convert("RGB"))
    new, weight, fit = recolour(old, pos, nrm, lit, pic)
    Image.fromarray(new).save(out_path)
    print("RECOLOUR fit s=%.1f px/m ox=%.1f oz=%.1f; front-seen %.0f%%; chroma old %.1f new %.1f" % (
        fit[0], fit[1], fit[2], 100 * float((weight > 0.5).mean()), mean_chroma(old), mean_chroma(new)))
    if len(argv) > 4:  # overlay: the model's texel positions splatted onto the picture, to judge the fit
        ov = pic.copy()
        px = np.clip(np.round(fit[1] + fit[0] * pos[..., 0]).astype(int), 0, pic.shape[1] - 1)
        py = np.clip(np.round(fit[2] - fit[0] * pos[..., 2]).astype(int), 0, pic.shape[0] - 1)
        edge = np.abs(nrm[..., 1]) < 0.15  # silhouette-ish texels
        ov[py[edge], px[edge]] = (255, 0, 255)
        Image.fromarray(ov).save(argv[4])


if __name__ == "__main__":
    main(sys.argv[1:])
