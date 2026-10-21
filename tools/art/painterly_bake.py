#!/usr/bin/env python3
"""Offline painterly bake: repaint the code-painted world atlases as brush strokes (numpy + Pillow, deterministic).

  tools/run_godot.sh -s res://tools/export_atlases.gd        # writes .bake/atlases/<atlas>.png
  python tools/art/painterly_bake.py [--recipe wash|oil|all] [--src .bake/atlases]

Per atlas: upscale (tiles x tile_scale, facades x facade_scale, bicubic), generalized Kuwahara (Papari et al.:
smooth sector kernels; each pixel takes the variance-weighted mean of its sectors, so flat areas become strokes
and edges stay sharp), a subtle directional brush grain, then a saturation lift. Tiles wrap (FFT convolution is
circular), so they stay seamless. Writes assets/textures/painted/<recipe>/<atlas>.webp (lossy WebP: a painted
1.3 MB PNG facade is ~0.2 MB, and brush grain hides the loss), bake.json (the recipe and
the sha256 of every input's RGBA bytes, checked by a Godot test) and one assets/manifest.json entry per file.
Recipes: tools/art/painterly_recipes.json.
"""
import argparse, hashlib, json, pathlib, sys, zlib
import numpy as np
from PIL import Image, ImageEnhance

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
RECIPES = pathlib.Path(__file__).resolve().parent / "painterly_recipes.json"
OUT_DIR = ROOT / "assets" / "textures" / "painted"


def sector_kernels(radius: float, sectors: int) -> list[np.ndarray]:
    """Gaussian-weighted, softly overlapping angular sectors (each kernel sums to 1)."""
    r = int(np.ceil(radius))
    y, x = np.mgrid[-r:r + 1, -r:r + 1].astype(np.float64)
    dist = np.hypot(x, y)
    gauss = np.exp(-(dist ** 2) / (2.0 * (radius / 2.0) ** 2)) * (dist <= radius)
    angle = np.arctan2(y, x)
    out = []
    for i in range(sectors):
        delta = np.angle(np.exp(1j * (angle - 2.0 * np.pi * i / sectors)))
        weight = np.clip(np.cos(delta * sectors / 4.0), 0.0, None) ** 2
        k = gauss * weight
        k[r, r] = gauss[r, r] / sectors
        out.append(k / k.sum())
    return out


def convolve(planes: np.ndarray, kernel: np.ndarray) -> np.ndarray:
    """Circular 2D convolution of (H, W, C) planes with a small centred kernel, by FFT."""
    h, w = planes.shape[:2]
    pad = np.zeros((h, w))
    kh, kw = kernel.shape
    pad[:kh, :kw] = kernel
    pad = np.roll(pad, (-(kh // 2), -(kw // 2)), axis=(0, 1))
    kf = np.fft.rfft2(pad)
    return np.fft.irfft2(np.fft.rfft2(planes, axes=(0, 1)) * kf[:, :, None], s=(h, w), axes=(0, 1))


def kuwahara(img: np.ndarray, radius: float, sectors: int, q: float) -> np.ndarray:
    """Generalized Kuwahara of an (H, W, 3) float image in 0..1."""
    both = np.concatenate([img, img * img], axis=2)
    num = np.zeros_like(img)
    den = np.zeros(img.shape[:2])
    for k in sector_kernels(radius, sectors):
        m = convolve(both, k)
        mean, sq = m[:, :, :3], m[:, :, 3:]
        var = np.clip(sq - mean * mean, 0.0, None).sum(axis=2)
        a = 1.0 / (1.0 + (255.0 * var) ** (0.5 * q))
        num += mean * a[:, :, None]
        den += a
    return np.clip(num / den[:, :, None], 0.0, 1.0)


def brush_grain(shape: tuple[int, int], amount: float, length: int, seed: int) -> np.ndarray:
    """Seamless directional noise around 1.0 (strokes along a slight diagonal)."""
    if amount <= 0.0:
        return np.ones(shape)
    rng = np.random.default_rng(seed)
    noise = rng.standard_normal(shape)
    k = np.zeros((length | 1, length | 1))
    c = k.shape[0] // 2
    for t in range(-c, c + 1):
        k[c + round(t * 0.3), c + t] = 1.0
    streaks = convolve(noise[:, :, None], k / k.sum())[:, :, 0]
    return 1.0 + amount * streaks / max(streaks.std(), 1e-6)


def bake_image(src: Image.Image, scale: int, recipe: dict, seed: int) -> Image.Image:
    up = src.convert("RGB").resize((src.width * scale, src.height * scale), Image.BICUBIC)
    img = np.asarray(up, dtype=np.float64) / 255.0
    for _ in range(int(recipe.get("passes", 1))):
        img = kuwahara(img, recipe["radius"] * scale / 4.0, int(recipe["sectors"]), recipe["q"])
    img = img * brush_grain(img.shape[:2], recipe["grain"], int(recipe["grain_length"]), seed)[:, :, None]
    out = Image.fromarray((np.clip(img, 0.0, 1.0) * 255.0 + 0.5).astype(np.uint8), "RGB")
    return ImageEnhance.Color(out).enhance(recipe["saturation"])


def digest(path: pathlib.Path) -> str:
    return hashlib.sha256(Image.open(path).convert("RGBA").tobytes()).hexdigest()


def bake_recipe(name: str, recipe: dict, src_dir: pathlib.Path, out_root: pathlib.Path) -> list[str]:
    out_dir = out_root / name
    out_dir.mkdir(parents=True, exist_ok=True)
    inputs, written = {}, []
    for src in sorted(src_dir.glob("*.png")):
        atlas = src.stem
        scale = int(recipe["tile_scale"] if atlas.startswith("tile_") else recipe["facade_scale"])
        out = out_dir / (atlas + ".webp")
        bake_image(Image.open(src), scale, recipe, zlib.crc32(atlas.encode())).save(out, quality=int(recipe["quality"]), method=6)
        inputs[atlas] = digest(src)
        written.append(f"textures/painted/{name}/{out.name}")
    with open(out_dir / "bake.json", "w", newline="\n", encoding="utf-8") as f:
        json.dump({"recipe": recipe, "inputs": inputs}, f, indent=1, sort_keys=True)
        f.write("\n")
    written.append(f"textures/painted/{name}/bake.json")
    return written


def update_manifest(assets: pathlib.Path, paths: list[str]) -> None:
    path = assets / "manifest.json"
    data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {"assets": []}
    keep = [e for e in data["assets"] if e.get("path") not in paths]
    for rel in paths:
        stem = pathlib.PurePosixPath(rel.removeprefix("textures/painted/")).with_suffix("").as_posix().replace("/", "_")
        keep.append({"id": "painted_" + stem, "path": rel, "source": "own", "licence": "own", "prompt": "painterly_bake"})
    data["assets"] = keep
    with open(path, "w", newline="\n", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--recipe", default="all", help="recipe name in painterly_recipes.json, or all")
    p.add_argument("--src", default=str(ROOT / ".bake" / "atlases"), help="exported atlases (tools/export_atlases.gd)")
    p.add_argument("--out", default=str(OUT_DIR))
    p.add_argument("--assets", default=str(ROOT / "assets"))
    args = p.parse_args(argv)
    recipes = json.loads(RECIPES.read_text(encoding="utf-8"))
    names = sorted(recipes) if args.recipe == "all" else [args.recipe]
    src_dir = pathlib.Path(args.src)
    if not any(src_dir.glob("*.png")) or any(n not in recipes for n in names):
        print("painterly_bake.py: no atlases in --src (run tools/export_atlases.gd) or unknown recipe", file=sys.stderr)
        return 1
    written = []
    for name in names:
        written += bake_recipe(name, recipes[name], src_dir, pathlib.Path(args.out))
        print(f"baked {name}")
    update_manifest(pathlib.Path(args.assets), written)
    return 0


if __name__ == "__main__":
    sys.exit(main())
