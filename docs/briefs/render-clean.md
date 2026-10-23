# Brief: render-clean (<= 60 lines)
You are in your own worktree on branch gemini/render-clean (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the godot-shader-developer skill.

## Why
Feras's playtest (inbox/playtest_01.png, inbox/playtest_02.png) (2026-10-24): "the ground textures flicker and are unstable" (roof floors under rain: dark wet
spots and ripple rings shimmer as the camera moves) and "the overall game looks poorly rendered" (jagged edges,
shimmering texture detail at distance).

## Read first
docs/MAP.md greps: rooftop_world, surface_painter, storm, paint_def, painted. content/world/storm.json; project.godot
[rendering]. tools/shot_level1.gd (renders roofs from the play camera); tools/fps_probe.gd (real FPS).

## What to build
1. Find every mesh/decal drawn on the roof floor plane (wet spots, puddles, ripple rings, floor tiles). Any two
   coplanar surfaces z-fight: lift overlays by a content number (start 0.02 m) or use render_priority / a decal; no
   two surfaces within 0.005 m of each other at the same spot.
2. Texture shimmer: painted surface and facade textures get mipmaps and anisotropic filtering
   (TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC; generate mipmaps where images are built in code).
3. Anti-aliasing in project.godot: MSAA 3D 2x plus screen-space AA off, OR TAA; pick the one that holds >= 60 FPS on
   the target laptop class (measure with tools/fps_probe.gd at 1920x1080; write the numbers in the final message).
4. Ripple rings: they must not pop; fade in/out over their life (alpha from content).
5. Renders: tools/shot_level1 to C:/dev/game/inbox/render_clean_r1.png and render_clean_r3.png, plus a second frame
   0.25 s later from a moved camera (render_clean_r1_b.png) so flicker is visible as a difference.

## Do NOT edit
`core/save/`
`core/game_state.gd`
`features/ui/`
`features/equipment/`
`features/map/`
`tools/check.sh`
`CLAUDE.md`
`docs/DECISIONS.md`
`HANDOFF.md`

## Tests
- A test that no two roof-floor overlay surfaces in souq_rooftops_v4 sit within 0.005 m of the floor or each other.
- A test that the painted surface textures report mipmaps (Image.has_mipmaps()) and the anisotropic filter.

## Checklist
- file: content/world/storm.json
- file: project.godot

## Proof
`bash tools/check.sh` raw last 15 lines; renders above; fps_probe numbers; final message ends with
`Built-by: Gemini 3.8 Flash (agy)`.
