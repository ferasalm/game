# Art bible: cyberpunk Sana'a 2150 (locked palette, scale and rules; owner may veto)
Pixel sprites are data: rows of palette letters in `content/art/sprites.json` ('.' = transparent), turned into
textures at runtime by PixelArt. Palette: `content/art/palette.json` (id "main", 32 colours, never add one casually).

## Scale and light
- 32 px = 1 m (sprites and textures). Humans about 64 px tall (Feras 2026-10-21). Today's sprites are
  Claude's stand-ins at the old scale (16 px = 1 m, humans 32 px); real ones replace them one by one.
- Feet on the bottom row. Art faces right (CharacterVisual mirrors it). Light comes from the upper left.
- 3 tones per material (dark / mid / light) plus a dark selective outline (`k`). No anti-aliasing, no gradients.
- Faces and visors get 1-2 pixel highlights. Neon is for accents only (a lens, a rig, a stripe), never big areas.

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
- Zayd: lean, light jacket over a brick futa wrap, red scarf at the neck, djanbeyyah at the belt (brass hilt, steel tip).
- Bilqis: hooded headscarf (indigo) with goggles (cyan) on the brow, long indigo coat with a magenta seam, a
  tool satchel behind the hip, a glowing cyan wrist rig on the front arm.
- Concession enforcer: bulky, wide pauldrons, visor helmet (cyan slit), water-drop emblem (u/a) on the chest, baton.
- Survey drone: round body, two rotor pods, one big lens (cyan and white glint), orange thruster.
- Workshop bench: low table, a glowing screen, tools, a brass-hilted blade.

## Pipeline
Gemini/Flow picture to sprite entry: `python tools/art/pixelize.py --in PIC.png --id ID [--height 64] [--out content/art/sprites.json]`; Zayd and Bilqis (2026-10-21) used `--contrast 1.3 --saturation 1.5 --outline` (soft painted art loses its hues when snapped; the outline is the dark 'k' ring).
Real sprites: Feras's Gemini picture -> pixelize.py -> touch-up in Pixelorama (free). Edit any sprite:
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
- Camera: exploring pitch ~26 deg (v1 was 31). Vista zone (`vista` cells in areas.json) eases to a low, wide pose that shows sky.
  Opening shot = `keys` in camera.json (positions relative to Zayd, `dof` scales the blur so stars stay sharp); any key/click skips.

## Motion and VFX
- Characters (`CharacterVisual`, numbers in content/art/visual.json): lit billboard shader (character.gdshader) with a
  guaranteed `min_light` share of the albedo plus a cool rim, so figures never go black against the moon. Idle breath,
  walk bob with squash and lean, dust puffs, turn squash, blob shadow; battle: anticipation, lunge with afterimages,
  hurt (flash, shake, slide), KO collapse + desaturate, revive glow, victory hop. Nearest filtering, no resampling.
- Effects (`content/combat/vfx.json`, one entry per ActionDef vfx kind plus "break"): layers of pooled additive quads
  (tex, anchors actor/target/feet/head/hand/mid, size, colour x energy, delay, time, drift, spin, span/chain/radial).
  Textures are painted in code (VfxTextures), hard-edged core + rim. Energy > 1 so the night bloom picks them up.
- Juice: per-move `impact`, `hitstop`, `shake`, `zoom`, `knock` in vfx.json; global numbers in juice.json (freeze scale,
  BREAK stamp, number pop and bounce, heavy threshold). Hitstop = Engine.time_scale dip for real time, always restored.
- Camera (content/combat/camera.json): ~1 s swoop from the exploration camera to a low pose (12.5 deg down), idle drift,
  leans toward the actor, pushes in on big moves, shakes, victory pose. After the battle the exploration camera cuts back.
- Look at every effect: `tools/shot_scene.gd` with `tools/vfx_gallery.gd`; the whole battle: `tools/shot_battle.gd`.
