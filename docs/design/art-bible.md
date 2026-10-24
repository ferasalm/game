# Art bible: cyberpunk Sana'a 2150 (locked palette, scale and rules; owner may veto)
Characters are live 3D models (docs/design/characters-3d.md). The old pixel sprites (rows of palette letters in
`content/art/sprites.json`, turned into textures by PixelArt) stay only as the fallback source. Palette: `content/art/palette.json` (id "main", 32 colours, never add one casually).

## Scale and light
- Godot units are metres. Characters are live 3D models, 2 m tall (Feras 2026-10-21; characters-3d.md).
  The pixel sprites are Claude's stand-ins, kept only as the fallback source.
- Feet on the model origin (the ground). Characters turn to face their move (`CharacterVisual.face_dir`); never
  mirror a model with a negative scale. Light comes from the upper left.
- Painted surfaces: one albedo per model with soft light and cavity darkening baked in. The shader bands the light
  into 3 tones (indigo shadow, mid, lit) with a rim and a `min_light` floor. Ink outline from screen-space depth and
  normals. No normal or roughness maps, low specular.
- Faces and visors get a painted highlight. Neon is for accents only (a lens, a rig, a stripe), never big areas;
  it comes from the emission mask.

## Palette (letter = colour)
- Outline and night: k #1a1420 outline, n #2b2540 deep indigo, i #3d3a73 indigo, j #5d5fa8 light indigo.
- Brick: r #6e3a2c dark, b #a35a3e mid, t #d08a5e light. Gypsum: h #9a8e7d shade, g #cfc3ad mid, w #f2ead8 white.
- Skin: s #8a5a3c, m #b57a52, l #d9a272. Leather and sand: o #4a4038, p #7a6650, q #b59a70.
- Qamariyya glass: R #c8383a red, Y #f0b83a amber, G #2f9e6a green, B #2f78c8 blue, V #8a4fb8 violet.
- Neon: C #3df0e0 cyan, M #ff3d9a magenta, L #b6ff3d lime, O #ff8a2a orange.
- Steel: d #3a4350 dark, e #6b7a8c mid, f #a9b8c8 light. White x #ffffff. Water: u #1f6f86 deep, a #5ad0ff light.
  Brass y #e8c070.

## Material tones
Skin s/m/l. Gypsum h/g/w. Brick r/b/t. Indigo cloth n/i/j. Leather o/p/q. Steel d/e/f. Glass: one qamariyya hue
plus x for the glint. Glow: C or M with a on top.

## Silhouettes (readable at 1x)
- Each model must read as a dark silhouette with its ink outline alone: a bulky or long shape, one big prop
  (jambiyah, baton, satchel) and one glow accent. Budgets: hero 15k triangles, enemy 10k, NPC 7k.
- Zayd: lean, light jacket over a brick futa wrap, red scarf at the neck, jambiyah at the belt (brass hilt, steel tip).
- Bilqis: hooded headscarf (indigo) with goggles (cyan) on the brow, long indigo coat with a magenta seam, a
  tool satchel behind the hip, a glowing cyan wrist rig on the front arm.
- Concession enforcer: bulky, wide pauldrons, visor helmet (cyan slit), water-drop emblem (u/a) on the chest, baton.
- Survey drone: round body, two rotor pods, one big lens (cyan and white glint), orange thruster. A rigid
  three-part model animated in code, not a skinned body.
- Workshop bench: low table, a glowing screen, tools, a brass-hilted blade.

## Pipeline
Characters (docs/design/characters-3d.md): CC0 stand-in bodies and moves (Quaternius) now, retargeted at import.
The owner's own later: Flow A-pose picture -> Hyper3D Rodin (model and rig) -> Blender only if needed. Painted textures go through
`tools/art/painterly_bake.py`. Every file gets a manifest entry with its source and licence.
Pixel fallback only (PixelSource, until a model exists). Gemini/Flow picture to sprite entry: `python tools/art/pixelize.py --in PIC.png --id ID [--height 64] [--out content/art/sprites.json]`; Zayd and Bilqis (2026-10-21) used `--contrast 1.3 --saturation 1.5 --outline` (soft painted art loses its hues when snapped; the outline is the dark 'k' ring).
Fallback sprites: Feras's Gemini picture -> pixelize.py -> touch-up in Pixelorama (free). Edit any sprite:
`python tools/art/sprite_png.py export --id ID --png ID.png`, paint, then `... import --id ID --png ID.png`
(lossless; refuses colours outside the palette). `... palette --out main.gpl` gives Pixelorama the palette.
Self-test: `python tools/art/test_sprite_png.py`.
Self-test: `python tools/art/test_pixelize.py`.

## Portraits
Dialogue portraits are chest-up painted pictures, one per speaker and expression (neutral, happy, angry, surprised),
facing right toward the text box, lit from the upper left, on a flat plain colour so the background can be keyed out.
Until the real ones exist the game draws pixel stand-ins from the sprites. Gemini prompts and the exact steps
(save, run tools/art/portrait.py, check in the game): docs/design/portrait-prompts.md. Files: assets/portraits/.

## Night sky, fog and camera
Look "night" (content/world/look.json) + sky "sanaa_night" (sky.json) + mist.json + camera.json. FPS on the Latitude
(Iris Xe, vsync off, noisy because other Godot runs share it): v1 daytime 157; night 128-135 walking, ~130 in the opening shot.
- Sky (`night_sky.gdshader`): zenith -> violet horizon + teal haze; stars = hash grid (`star_scale` cells per radian,
  `star_density` share of cells lit, `star_size` in cell units); milky way band; moon (`moon_size` in radians, `moon_energy` > 1
  so it blooms, two halos); 2 cloud layers (`coverage` up = more sky covered, `opacity` < 1 keeps stars visible); city glow
  toward `glow_yaw` (orange low, magenta high). Only costs pixels where sky shows (~0-10 FPS at full sky; radiance 32, rendered once).
- Light: moon = `sun_*` (cool, soft shadows), fill = `fill_*` (camera side, no shadows, keeps sprites readable). Ambient = sky mixed
  with an indigo tint (`ambient_sky_mix`). AgX + `exposure`; `glow_threshold` < 1 makes windows and the moon bloom.
- Fog: `fog_density` (depth, tinted by `fog_color` and the sky through `fog_aerial`), `fog_height*` pools it below y = 0.45
  (the street al-Saila). `volumetric_fog` is off: it is expensive on the Iris Xe (not measured); turn it on only for a "high quality" option.
- Mist (`mist.json`): 2 planes (street y 0.32, roofs y 0.62), 1 noise + 1 depth sample, about 5-7 FPS together.
- Camera (superseded 2026-10-24: too close, the environment overhaul sets a farther camera): close follow outdoors, automatic, a three-quarter side angle of ~32 deg; when a wall blocks the view it
  rises toward isometric (DECISIONS 2026-10-23). Vista zone (`vista` cells in areas.json) eases to a low, wide pose
  that shows sky. Opening shot = `keys` in camera.json (positions relative to Zayd, `dof` scales the blur so stars
  stay sharp); any key/click skips.

## Motion and VFX
- Characters (`CharacterVisual`; ModelDef and ClipDef in content/art/models.json and clips.json; every number is a
  placeholder tuned on renders): live 3D models with the painted skin shader and ink outline. Locomotion blends
  idle, walk and run by speed, with playback rate = speed / stride so feet do not slide. Battle moves play in
  segments: wind-up (about 0.7x), a hold (about 80 ms), the strike (about 1.8x), then recovery. The impact frame
  fires an event and battle waits on it, never on a timer. Hit-stop: a 60-90 ms freeze on attacker and target
  (`CharacterVisual.hit_stop`). The weapon has a ribbon trail from hilt to tip and an arc smear on the strike.
  Squash is on the body node; lean 6-8 degrees from acceleration; turns about 900 deg/s. Idle breath, dust, hurt
  flash and shake, KO collapse and desaturate, revive glow, victory hop, blob contact shadow.
- Effects (`content/combat/vfx.json`, one entry per ActionDef vfx kind plus "break"): layers of pooled additive quads
  (tex, anchors actor/target/feet/head/hand/mid, size, colour x energy, delay, time, drift, spin, span/chain/radial).
  Textures are painted in code (VfxTextures), hard-edged core + rim. Energy > 1 so the night bloom picks them up.
- Juice: per-move `impact`, `hitstop`, `shake`, `zoom`, `knock` in vfx.json; global numbers in juice.json (freeze scale,
  BREAK stamp, number pop and bounce, heavy threshold). Character hit-stop is the per-model freeze above, never
  Engine.time_scale; the global dip in juice.json is the old path and must not be used for models.
- Camera (content/combat/camera.json): ~1 s swoop from the exploration camera to a low pose (12.5 deg down), idle drift,
  leans toward the actor, pushes in on big moves, shakes, victory pose. After the battle the exploration camera cuts back.
- Look at every effect: `tools/shot_scene.gd` with `tools/vfx_gallery.gd`; the whole battle: `tools/shot_battle.gd`.
