# Brief: skin-bake (<= 60 lines)
You are in your own worktree on branch gemini/skin-bake (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Python only: no Godot code, no content or scene changes.

## Why
The owner picked painted route B (DECISIONS 2026-10-23): repainted textures on live 3D. The world textures already go
through tools/art/painterly_bake.py; the character skins (the Rodin textures) must get the same painted pass.

## Read first
tools/art/painterly_bake.py (all of it, ~150 lines), tools/art/painterly_recipes.json,
tools/art/test_painterly_bake.py, content/art/models.json (only the "skin" fields).

## What to build
1. A new recipe "skin" in painterly_recipes.json: {"kind": "skin", "radius": 5, "sectors": 8, "q": 12, "passes": 1,
   "grain": 0.03, "grain_length": 9, "saturation": 1.15, "quality": 92}. Here radius is in texture pixels (scale 1).
2. In painterly_bake.py a function bake_skins(name, recipe, models_path, res_root, out_root) -> list[str]: for every
   item in content/art/models.json with a "skin" field ("res://assets/characters/t_*.png"), read that PNG, run the
   same kuwahara + brush_grain + saturation as bake_image but at scale 1 with the radius as given, KEEP THE ALPHA
   CHANNEL unchanged, and write assets/textures/painted/<name>/<stem>.webp (RGBA, the recipe's quality). Write
   bake.json (recipe + sha256 of every input, the same format as bake_recipe) and return the asset paths.
3. main(): `--recipe skin` runs bake_skins instead of bake_recipe; `--recipe all` runs both kinds. Update the
   manifest with update_manifest as the other recipes do. Keep the module docstring accurate (one added line).
4. Run it once: `python tools/art/painterly_bake.py --recipe skin` and commit the outputs (webp, bake.json, manifest).
   Keep every function <= 40 lines and the file <= 200 lines (split helpers if needed).

## Do NOT edit
Anything outside tools/art/, assets/textures/painted/skin/ and assets/manifest.json. Not content/art/models.json
(the lead wires the painted skins into the game after review). No *.import files.

## Tests (tools/art/test_painterly_bake.py, run with `python -m pytest tools/art -q`)
bake_skins on a small temporary models.json + two tiny RGBA PNGs: same size out, alpha identical, deterministic (two
runs give equal bytes), bake.json lists both inputs; a model item without "skin" is skipped.

## Proof
`python -m pytest tools/art -q` raw last 5 lines; `bash tools/check.sh` raw last 15 lines; small commits; final
message ends with `Built-by: Gemini 3.8 Flash (agy)`.
