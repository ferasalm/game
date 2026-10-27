"""Tests tools/art/recolour.py with tiny synthetic texels and a picture. Run: python tools/art/test_recolour.py"""
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import recolour  # noqa: E402

BG, RED = (225, 225, 228), (190, 60, 40)


def picture():
    pic = np.zeros((200, 100, 3), np.uint8); pic[:] = BG
    pic[20:190, 30:70] = RED  # the figure: 2 m tall, 0.47 m wide at 85 px/m
    pic[5:7, 5:7] = (0, 0, 0)  # an ink speck the mask must drop
    return pic


def texels():
    """4x4 texels: row 0 faces the camera, row 1 faces sideways, rows 2-3 face away (the back)."""
    n = 4
    xs = np.linspace(-0.15, 0.15, n)
    pos = np.zeros((n, n, 3)); pos[..., 0] = xs[None, :]; pos[..., 2] = 1.0; pos[0, 0, 2] = 2.0
    nrm = np.zeros((n, n, 3))
    nrm[0, :] = (0, -1, 0); nrm[1, :] = (-0.8, -0.6, 0); nrm[2:, :] = (0, 1, 0)
    lit = np.zeros((n, n)); lit[0, :] = 1.0; lit[1, :] = 0.6
    old = np.zeros((n, n, 3), np.uint8); old[:] = 128; old[0, 1] = 90; old[0, 2] = 170  # lightness detail
    return old, pos, nrm, lit


def main():
    rgb = np.array([[[10, 200, 30], [250, 250, 250]]], np.uint8)
    assert np.abs(recolour.lab_to_srgb(recolour.srgb_to_lab(rgb)).astype(int) - rgb).max() <= 1, "Lab round trip"
    assert np.allclose(recolour.box_blur(np.full((5, 6), 3.0), 2), 3.0), "blur keeps a constant"
    pic = picture()
    mask = recolour.figure_mask(pic)
    assert not mask[5, 5] and mask[100, 50], "speck dropped, figure kept"
    s, ox, oz = recolour.fit_picture(mask, 2.0)
    assert abs(s - 85) < 1.5 and abs(ox - 49.5) < 1 and abs(oz - 189) < 1, (s, ox, oz)
    old, pos, nrm, lit = texels()
    new, weight, _ = recolour.recolour(old, pos, nrm, lit, pic, blur_ab=2, blur_l=4)
    lab = recolour.srgb_to_lab(new)
    assert (weight[0, 1:] > 0.9).all() and (weight[2:] == 0).all(), "front seen, back not"
    assert weight[0, 0] == 0, "a texel projecting onto the background is not coloured from it"
    assert (lab[0, 1:, 1] > 20).all(), "front texels take the picture's red"
    assert (lab[2:, :, 1] > 20).all(), "back texels take the sideways texels' red, not grey"
    assert lab[0, 1, 0] + 10 < lab[0, 2, 0], "old lightness detail kept (90 stays darker than 170)"
    assert recolour.mean_chroma(new) > recolour.mean_chroma(old) + 20, "chroma rises"
    print("recolour self-test ok")


if __name__ == "__main__":
    main()
