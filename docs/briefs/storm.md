# Brief: storm (<= 60 lines)
You are in your own worktree on branch gemini/storm (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Load the technical-artist skill (.agents/skills/technical-artist).

## Why
Owner 2026-10-23: level 1 is a night storm with rain over cyberpunk old Sana'a. Spec: docs/design/level-1.md section 5
("Storm" bullet). Another builder is rebuilding the roofs right now, so the storm is a SELF-CONTAINED layer that works
on any area: it reads only the camera and the area's floor tiles.

## Read first
docs/MAP.md lines for mist_def, mist_builder, mist.gdshader, rooftop_world, sky_def, sky_builder, fps_probe;
features/world/rooftop/rooftop_world.gd (line 21 builds the mist: the storm hooks in the same way); content/world/mist.json.

## What to build (new folder features/world/weather/: defs/, view/, tests/; content/world/storm.json)
1. StormDef (read-only Def from content/world/storm.json, kind "storm", one item "night_storm"); every number below lives
   there, none in code.
2. Rain streaks: a GPUParticles3D box that follows the camera (box 24 x 14 x 24 m, 3000 streaks at most, count from JSON),
   thin stretched quads falling at ~14 m/s with a slight wind slant, unshaded, additive, pale blue-white, alpha 0.25-0.4,
   so neon behind them shows through. No collision (cheap); streaks die at the camera's floor height minus 2 m.
3. Splashes: a second, smaller particle system near the camera (box 10 x 10 m on the player's floor height) emitting tiny
   ring flashes (ripple sprites that grow and fade in 0.3 s), 120 at most.
4. Puddles: seeded scatter of 6-10 puddles per area on floor tiles (from the AreaDef the builder gets), never within 0.6 m of
   a wall or parapet; each a flat irregular quad 0.01 m above the floor with a shader: low roughness, darkened floor tint,
   a fake reflection (the sky's ambient colour + a soft magenta/cyan neon smear from storm.json) and rain ripple rings
   animated in the shader (no extra particles). No screen-space reflections (60 FPS on Iris Xe).
5. Drips: StormBuilder.add_drips(host, points: Array[Vector3]) makes a short drip stream (one particle every 0.4-0.9 s,
   tiny splash on landing) at each point; the rooftop calls it with an empty list for now (the dressing pass gives points).
6. Steam: StormBuilder.add_steam(host, points) makes a soft rising steam plume (billboard puffs, 40 at most each) per point.
7. Lightning: rare and quiet: every 25-60 s (seeded random), a 0.15 s double flash of the sky (a sky shader uniform or a
   short boost of the moon light's energy) far behind the mountains; no sound yet. A flag in storm.json turns it off.
8. Hook: ONE line in features/world/rooftop/rooftop_world.gd after the mist line: the StormBuilder.build(...) call, only
   when the area has "weather": "storm" (add that optional field to AreaDef, default ""; set it on the current area).
9. A preview: features/world/weather/storm_preview.tscn (the rooftop with the storm) for renders and fps_probe.

## Do NOT edit
features/combat/, content/combat/, features/dialogue/, content/dialogue/, features/items/, content/economy/,
features/prototype/ (another session owns them); content/world/areas.json beyond the one "weather" field;
content/world/tiles.json, buildings.json, camera.json, places, walk_graph, follow_cam (the level1-blockout builder owns
them); features/world/logic/framed_shots.gd; tools/art/; docs/design/; HANDOFF.md; docs/DECISIONS.md.

## Tests
StormDef parses every field and rejects a bad one; particle counts never exceed the JSON caps; puddles stay on floor tiles,
>= 0.6 m from walls, same seed same places; drips/steam make one emitter per point; lightning off when the flag is off;
an area without "weather" builds no storm.

## Proof
`bash tools/check.sh` raw last 15 lines; renders (not headless, LESSONS 2) of storm_preview from the play camera, one
mid-lightning, to C:/dev/game/inbox/storm_*.png (960x540); the fps_probe average and worst FPS for storm_preview vs the
plain rooftop in the final message; small WIP commits; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
