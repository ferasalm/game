# Brief: neon-roof (Neon Glitch prison roof: iso exploration; <= 60 lines)
You are in your own worktree on your own branch made from neon/first-playable. Follow GEMINI.md / AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
Feras: "it will be an isometric game similar to Hades, with our unique art style". First playable: Rydan escapes onto
the prison roof (his painted iso plate), walks it with free 8-way movement, Bilqis kills a floodlight over comms.

## Read first
docs/design/first-playable.md (all). features/neon/ (defs, logic/iso_walk.gd, logic/iso_dir.gd, view/iso_actor.gd,
tests/test_neon_foundation.gd): USE these, never copy them. content/neon/rooms.json (prison_roof), sprites.json.
Dialogue: grep docs/MAP.md "features/dialogue/" for the box scene and how a dialogue id is shown and finishes.

## What to build (all in features/neon/roof/ + content/neon/roof_*.json + localization/neon_roof.csv)
1. `roof_scene.tscn` + `roof_scene.gd` (class RoofScene, Node2D): Sprite2D plate from NeonRoomDef.plate (top-left at
   0,0); a `%World` Node2D with y_sort_enabled holding every IsoActor; occluders as Polygon2D textured with the plate
   (uv = polygon) inside %World, node y = baseline; Camera2D following the hero, limits = room size, smoothing on.
   Room id is an @export (default &"prison_roof"). API: `func hero() -> IsoActor`, `func room() -> NeonRoomDef`,
   `func set_exploring(on: bool)` (input and patrols off/on), `func guards() -> Array[IsoActor]`,
   `signal battle_requested(foes: Array[IsoActor], contact: Vector2, ambush: bool)`, `signal exited`.
2. Hero: IsoActor set "rydan" at room.spawn; input move_left/right/up/down (and a stick) -> IsoWalk.velocity
   (speed in content/neon/roof_rules.json, start 330 px/s) -> IsoWalk.step; face the velocity; "run" while moving,
   "idle" when not. Opening beat: the hero starts hidden, the hatch "bursts" (screen shake 0.25 s, a short white
   flash on the hatch spot) and he appears; then a prompt strip shows move keys for 4 s.
3. Guards: one IsoActor set "guard" per room.guards entry, walking its path back and forth (speed 90 px/s, "walk"
   anim, pause 1.2 s at each end, facing their motion). When the hero's feet come within 70 px of any guard while
   exploring: exploring stops and battle_requested fires once with ALL living guards, contact = midpoint, ambush =
   true when that guard faces away from the hero (dot(facing vector, to-hero) < 0). A pure helper decides this:
   `features/neon/roof/logic/contact_rules.gd` (class ContactRules: touching(), is_ambush()).
4. Interactables from room.interactables: an "interact" prompt (localized room prompt text + key glyph) when the hero
   is within radius. fuse_box: plays dialogue `neon_roof_fuse` (Bilqis on comms, speakers bilqis_ng and rydan, 3-5
   short lines you write in localization/neon_roof.csv; tone: terse, dry, she is outside and timing the guards),
   then the floodlight polygon fades from a light-blue additive glow to a dark multiply overlay over 0.6 s with two
   flickers. cable_line: only after `func mark_won()` was called; then emits `exited`.
5. Rain: a light animated rain overlay (GPUParticles2D or a scrolling shader over the screen, never on the HUD).
6. `roof_scene.tscn` runs on its own (F6): no battle system needed; battle_requested is only emitted.

## Do NOT edit
`features/neon/defs/`
`features/neon/logic/`
`features/neon/view/`
`features/neon/battle/`
`features/neon/start/`
`features/combat/`
`core/`
`content/neon/rooms.json`
`content/neon/sprites.json`
`assets/`
New dialogue entries go in content/dialogue/dialogues.json (append only, ids neon_roof_*).

## Tests (features/neon/roof/tests/)
- ContactRules: touching radius, ambush from behind true, from the front false.
- RoofScene headless: hero spawns at room.spawn; a step into a wall slides; guards walk their paths; touching a
  guard emits battle_requested once with both guards; cable_line does nothing before mark_won() and exits after.

## Checklist
- file: features/neon/roof/roof_scene.tscn
- has: features/neon/roof/roof_scene.gd :: signal battle_requested
- has: features/neon/roof/roof_scene.gd :: func mark_won
- has: features/neon/roof/logic/contact_rules.gd :: static func is_ambush
- test: features/neon/roof/tests/test_roof_scene.gd :: test_touching_guard_requests_battle_once
- key: localization/neon_roof.csv :: NEON_ROOF_MOVE_HINT

## Proof
`bash tools/check.sh` raw last 15 lines; a render: tools/shot_neon_roof.tscn (copy tools/shot_dialogue.tscn's wrapper
pattern) -> C:/dev/game/inbox/neon_roof.png (hero walking, a guard visible); small WIP commits.
