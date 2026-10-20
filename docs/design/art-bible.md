# Art bible: cyberpunk Sana'a 2150 (locked palette, scale and rules; owner may veto)
Pixel sprites are data: rows of palette letters in `content/art/sprites.json` ('.' = transparent), turned into
textures at runtime by PixelArt. Palette: `content/art/palette.json` (id "main", 32 colours, never add one casually).

## Scale and light
- 16 px = 1 m (sprites and textures). Humans about 32 px tall, 16-20 wide; drone 16x16; bench 24x16.
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
Gemini/Flow picture to sprite entry: `python tools/art/pixelize.py --in PIC.png --id ID [--height 32] [--out content/art/sprites.json]`.
Self-test: `python tools/art/test_pixelize.py`.

## Portraits
Dialogue portraits are chest-up painted pictures, one per speaker and expression (neutral, happy, angry, surprised),
facing right toward the text box, lit from the upper left, on a flat plain colour so the background can be keyed out.
Until the real ones exist the game draws pixel stand-ins from the sprites. Gemini prompts and the exact steps
(save, run tools/art/portrait.py, check in the game): docs/design/portrait-prompts.md. Files: assets/portraits/.
