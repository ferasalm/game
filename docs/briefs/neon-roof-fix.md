# Brief: neon-roof-fix (fix pass on the merged prison roof; <= 60 lines)
You are in your own worktree on your own branch made from neon/first-playable. Follow AGENTS.md / GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
The prison roof (features/neon/roof/, brief docs/briefs/neon-roof.md) merged; a review found the opening beat
missing and actors that keep running in place while the roof is paused (dialogue, fight). Feras plays this first.

## Read first
docs/briefs/neon-roof.md. features/neon/roof/ (all), features/neon/view/iso_actor.gd (read only),
content/neon/roof_rules.json, content/neon/rooms.json (prison_roof: spawn, hatch, interactables; read only).

## What to fix
1. Opening beat (brief item 2): the hero starts hidden at the hatch; the camera starts ON the hatch (no ease from
   0,0: snap the camera and reset smoothing once); after `burst_delay` (0.6 s) the hatch bursts: screen shake 0.25 s,
   a short white flash on the hatch spot, the hero appears playing "run" one short hop out of the hatch onto spawn;
   then the move prompt strip shows for its seconds. Input is ignored until the hero has landed. Numbers in
   roof_rules.json.
2. set_exploring(false): the hero and every guard play "idle" (unless the caller later plays something else), the
   interact prompt hides, the move prompt hides. set_exploring(true) resumes. Guards that fought (after
   battle_requested) never patrol again (already done: keep the test test_guards_stop_patrolling_after_the_fight).
3. A null room (bad room_id): push_error once and do nothing in _process (no null dereference every frame).
4. roof_rules.json interact_radius: use it as the fallback when an interactable has no radius, or delete it.
5. Numbers out of code into roof_rules.json + NeonRoofRulesDef: ContactRules radius default (70), the HUD prompt 4.0 s,
   the floodlight fade 0.6 and its flicker steps (keep the fade at exactly floodlight_fade_seconds, flickers inside
   it). NeonRoofRulesDef field defaults may stay as fallbacks.
6. RoofPatrol walks every point of its path (ping-pong), not only points 0 and 1.
7. tools/shot_neon_roof.gd: the proof render shows the hero mid-run (feed a held move input or play "run" after the
   scene's own update), and commit its .uid.

## Do NOT edit
`features/neon/defs/`
`features/neon/logic/`
`features/neon/view/`
`features/neon/battle/`
`features/neon/start/`
`features/neon/cold_open/`
`features/neon/neon_game.gd`
`features/neon/neon_game.tscn`
`features/combat/`
`content/combat/`
`content/neon/rooms.json`
`content/neon/sprites.json`
`assets/`
`core/`
Keep RoofScene's public API (hero, room, guards, world, set_exploring, mark_won, interact, the two signals).

## Tests (features/neon/roof/tests/)
- Opening: the hero is hidden right after _ready and visible on spawn after burst_delay + the hop; input before
  landing does not move him.
- set_exploring(false) after a battle_requested: hero and guards show "idle", the interact prompt is hidden.
- "fires only once": call set_exploring(true) before the second _process so the guard against a second request is
  really exercised.
- Wall slide through RoofScene: hold a move input toward the nearest wall edge for 2 s; the hero stays on the floor
  and his position still changes along the edge.
- Fuse box: interact at the fuse box, finish the dialogue, the floodlight reaches its dark state after its fade.
- A three-point path visits all three points.

## Checklist
- test: features/neon/roof/tests/test_roof_scene.gd :: test_opening_hides_hero_until_landing
- test: features/neon/roof/tests/test_roof_scene.gd :: test_pause_idles_actors
- has: features/neon/roof/roof_scene.gd :: func world

## Proof
`bash tools/check.sh` raw last 15 lines; render tools/shot_neon_roof.tscn -> C:/dev/game/inbox/neon_roof.png (hero
mid-run, a guard visible); small WIP commits.
