# Night Sana'a: the city around the rooftop (geography is loose; Feras may correct it)
Everything is procedural and data-driven: content/world/{buildings,skyline,tiles}.json, painters in
features/world/logic/, builders in features/world/view/. Demo: `skyline_demo.tscn -- <iso|vista|wide|south|west|east|close|roof> [building]`.

## Vocabulary used (Sana'a tower-house)
- Basalt stone base (dark, 1-2 floors, small slit windows, arched wooden door) under fired-brick upper floors.
- White gypsum friezes at the top of each brick floor: zigzag, triangles, rosettes (the signature of the city).
- Windows with thick white gypsum frames (dark glass, lit amber glass or wooden shutters) and a sill.
- The qamariya: a semicircle over each window, white tracery, five glass segments (R Y G B V). Lit windows glow
  amber and their qamariya glows in its colours (emission map); unlit ones are dark.
- White crenellated parapet with a corner merlon per building: plain, stepped (three steps) or horned.
- Roof extras (2150): water tank, satellite dish (cyan LED), antenna (red beacon), small solar panel.
- Palette letters only (art-bible): brick r/b/t, gypsum h/g/w, basalt n/d/e, glass R Y G B V, wood o/p/s. 32 px = 1 m.

## Places (x east, z south, area = x 0..26, z 0..18, -Z north; ground/street level y = -18)
- Old City at the centre. Near band 5-30 m, mid 30-90 m (the same 8 tower-houses, tops from -3 to +9 m around the
  rooftop level), far 90-250 m (unshaded dotted boxes, window dots, tinted per box).
- al-Saila: the sunken paved street along z at x = 18 (continues the street tile at x 17-19), kept free of houses.
- Great Mosque minarets: (4, -58) 36 m and (28, -70) 30 m, north. Bab al-Yaman gate: (18, 95) south, at the end of
  al-Saila, towers 20 m. Jabal Nuqum ridge: (300, -140) running north-south, east. Haddah megacity: (-230, 240)
  south-west, 14 slim towers up to 220 m with cyan/magenta neon. Bayt Baws: (40, 260) far south, crag with 12 houses.
- Camera facts (superseded 2026-10-24: too close, see the environment overhaul): close follow outdoors, automatic, a three-quarter side angle of ~32 deg; when a wall blocks the
  view it rises toward isometric (DECISIONS 2026-10-23). The camera (FOV 30) sees only ground inside ~19 m, so it
  shows the nearest rooftops only; the landmarks need a low or wide camera (the sky builder's vista camera).
  Looking north: both minarets, street canyon; east: ridge; south: Bab al-Yaman, village; south-west: megacity.

## Textures and tiles
- Tile patterns (`pattern` in tiles.json): roof_plaster, plaster_worn, gypsum, planks, paving, basalt, brick. 128 px =
  4 m, seamless, world-space triplanar so texels stay square across tiles; one material per pattern.
- Facades: front and side painted into one atlas per building type (mipmapped, nearest). Seeded, deterministic.

## Budget (Iris Xe laptop, prototype_main, vsync off)
- About 8 building meshes x 3 surfaces (facade, trim, beacons), batched per 80 m square (culling) with MultiMesh:
  ~220 blocks, ~64k primitives and 107 draw calls in the whole exploration frame. Far boxes: one material.
- Landmarks: 1 mesh, 2 surfaces. Ground and street: 2. No skyline node casts shadows.
- FPS: 157 before, 139-147 with the skyline (probe, 5 s). Build time about 0.5 s (painting at load; cache later if needed).
- Rule for more content: new building = one JSON item (one more mesh and atlas); keep near blocks <= 120.

## Rooftop dressing
- Night values: look "night" (moon #7f9bff 0.7, fill 0.16, ambient 0.3, exposure 0.9) plus per-tile `tint` in tiles.json
  (moonlit blue-grey plaster); warm light only where a lamp, lantern or doorway is.
- Area data (areas.json): `buildings` and `props` = [{ref, x, z, y?, yaw?, id?}], `lights` (LightSpec), `signs` (SignSpec),
  `canyon` (al-Saila walls + channel), `light_budget` (real OmniLights, max 8) and `light_fade`. Footprint cells use the hidden
  solid tile "footprint"; "street" is hidden too, so the sunken street shows below. Props: content/world/props.json, parts =
  box/frustum + palette letter (glow, blink, pattern, group), optional `light`, `collide`, `chest`.
- Lights: every light with `pool` gets a fake additive pool (one MultiMesh); only the nearest few get an OmniLight3D (no shadows).
- Signs: Label3D in Noto Sans Old South Arabian, text from localization/world.csv (Musnad only, Musnad runs read
  right to left), fitted to the board, HDR so they bloom; `flicker` dips one like a failing tube.
- Chests: props with `chest: true` (ids chest_saila, chest_mafraj); `Rooftop.chest_opened(chest_id)` fires once per chest.
- Fog: mist defs take `rect`, `stack`/`step` (sheets forming a volume in the canyon) and `hole` (wisps never over the roof).
- Frame tool: `rooftop_shot.tscn -- <x> <z> [cam x y z, target x y z, fov]`. FPS on the Latitude: ~100 (probe).
