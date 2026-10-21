#!/usr/bin/env python3
"""Self-test for painterly_bake.py and figure_cut.py on synthetic pictures in a temp dir; exit 1 on any failure."""
import json, pathlib, sys, tempfile
import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import painterly_bake as pb  # noqa: E402
import figure_cut  # noqa: E402

RECIPE = {"tile_scale": 2, "facade_scale": 2, "radius": 6, "sectors": 8, "q": 8, "passes": 1,
          "grain": 0.03, "grain_length": 7, "saturation": 1.0, "quality": 95}


def test_kuwahara_flattens_noise_keeps_edges() -> None:
    rng = np.random.default_rng(3)
    img = np.zeros((64, 64, 3))
    img[:, 32:] = 1.0
    noisy = np.clip(img + rng.normal(0, 0.08, img.shape), 0, 1)
    out = pb.kuwahara(noisy, 4.0, 8, 8)
    assert out[8:56, 4:24].std() < noisy[8:56, 4:24].std() * 0.6, "flat areas get smoother"
    assert out[32, 36].mean() - out[32, 27].mean() > 0.8, "the black/white edge stays sharp"


def test_kernels_sum_to_one() -> None:
    for k in pb.sector_kernels(5.0, 8):
        assert abs(k.sum() - 1.0) < 1e-9


def test_tiles_stay_seamless() -> None:
    rng = np.random.default_rng(5)
    src = Image.fromarray((rng.random((32, 32, 3)) * 255).astype(np.uint8), "RGB")
    out = np.asarray(pb.bake_image(src, 2, RECIPE, 1), dtype=np.float64)
    seam = np.abs(out[:, 0] - out[:, -1]).mean()
    inner = np.abs(out[:, 31] - out[:, 32]).mean()
    assert seam < inner * 2.0 + 4.0, f"wrap seam {seam:.1f} vs inner step {inner:.1f}"


def test_bake_is_deterministic_and_records_inputs() -> None:
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        src, assets = root / "src", root / "assets"
        src.mkdir()
        assets.mkdir()
        img = Image.new("RGBA", (16, 16), (200, 100, 50, 255))
        ImageDraw.Draw(img).rectangle((4, 4, 11, 11), fill=(20, 30, 90, 255))
        img.save(src / "tile_test.png")
        runs = []
        for name in ("a", "b"):
            written = pb.bake_recipe(name, RECIPE, src, assets / "textures" / "painted")
            runs.append((assets / "textures" / "painted" / name / "tile_test.webp").read_bytes())
            pb.update_manifest(assets, written)
        assert runs[0] == runs[1], "same input, same recipe: same bytes"
        record = json.loads((assets / "textures" / "painted" / "a" / "bake.json").read_text())
        assert record["inputs"]["tile_test"] == pb.digest(src / "tile_test.png")
        manifest = json.loads((assets / "manifest.json").read_text())
        ids = {e["id"] for e in manifest["assets"]}
        assert {"painted_a_tile_test", "painted_a_bake", "painted_b_tile_test"} <= ids, ids
        assert all(e["licence"] == "own" and e["prompt"] == "painterly_bake" for e in manifest["assets"])


def test_figure_cut_keys_the_green() -> None:
    img = Image.new("RGB", (200, 160), (30, 220, 40))
    ImageDraw.Draw(img).ellipse((20, 20, 80, 140), fill=(180, 90, 60))
    out = figure_cut.cut(img, "left", 60, 80)
    assert out.height == 80 and out.mode == "RGBA"
    assert out.getpixel((0, 0))[3] == 0 and out.getpixel((out.width // 2, 40))[3] == 255


def main() -> int:
    tests = [v for k, v in globals().items() if k.startswith("test_")]
    for t in tests:
        t()
    print(f"test_painterly_bake: {len(tests)} tests ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
