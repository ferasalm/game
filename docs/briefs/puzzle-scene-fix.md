# Brief: puzzle-scene-fix (review fixes on your own branch oc/puzzle-scene; <= 60 lines)
You are in your own worktree on branch oc/puzzle-scene; it already holds your puzzle-scene build (brief:
docs/briefs/puzzle-scene.md). Follow GEMINI.md and AGENTS.md. Load the godot-gameplay-scripter skill.

## Why
Claude's render review of inbox/puzzle_*.png found these; fix exactly these, nothing else. Your last run built
nothing: work only inside this worktree (never make another worktree or read outside it). A test FAIL with
"ERROR: Parameter \"mem\" is null" means the PC ran out of memory, not your code: rerun check.sh once. Delete
.check_run.log (git rm) and commit after each numbered item.

## What to build
1. No water before the light lock is solved: the valve is shut until then. Water strips, gauge, dock sag, the
   return-grate line (PUZZLE_WATER_RETURN) and water hints all stay off until LightLock.solved(); then the water
   flows from WaterNet's start state.
2. Frame the goal: the canyon spout and its gauge must be inside the camera view in every render. Change only
   content/puzzles/puzzle_yard.json: camera at (1.0, 7.5, 12.0) looking at (1.0, 0.5, -1.0), fov 56; canyon outlet
   at (7.8, -1.0, 2.5). Check the four renders show the gauge.
3. Renders: put the stand-in player at (-1.5, 0, 3.0) in tools/shot_puzzles.gd, so it hides no piece.
4. Mirrors read at play distance: brass box 0.15 x 1.0 x 0.8 (content), plus a 0.3 m brass disc on top.
5. core/defs/def.gd is shared by every Def: if you changed it, keep only a minimal, typed helper that no other Def
   can break, or move it into features/puzzles/defs/ instead.
6. A test for item 1: before the light lock is solved, every water edge has no strip and the grate line is not shown.

## Do NOT edit
`features/world/`
`content/world/`
`features/combat/`
`features/dialogue/`
`features/items/`
`core/game_state.gd`
`features/puzzles/logic/`

## Proof
`bash tools/check.sh` raw last 15 lines; re-render all four to C:/dev/game/inbox/puzzle_<arg>.png; small commits;
final message ends with `Built-by: deepseek-v4.1-flash (opencode, Cloudflare)`.
