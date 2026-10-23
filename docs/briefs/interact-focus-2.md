# Brief: interact-focus (<= 60 lines; the level-1 blockout is merged into main; tayramana is merged: the workbench is in its room)
You are in your own worktree on branch oc/interact-focus-2 (made from main; a first attempt edited rooftop.gd, wrote no tests and left 13 failing: do not repeat that). Follow GEMINI.md,
including <review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/) if one fits.

## Why
Feras approved (rpg-menus.md 0): pressing interact at the shop, the workshop bench or the sabil eases the camera in to a
framed shot of the spot, then the menu opens; closing it eases back. Automatic: the player never controls the camera.

## Read first
docs/design/rpg-menus.md 0 (THE SPEC); docs/DECISIONS.md camera lines (2026-10-23); features/world/interact/
interact_spot.gd, stall_spot.gd, sabil_spot.gd; features/world/workshop/workshop_spot.gd; features/world/rooftop/
rooftop.gd (freeze_actors, read only), rooftop_camera.gd and features/world/logic/framed_shots.gd (read only: the
framing idea); features/world/player/player.gd (set_active); features/ui/view/ui_stack.gd (open returns the UiScreen,
`closed` signal); content/ui/style.json.

## What to build
1. Content: content/ui/focus.json kind "focus_shot" (FocusShotDef in features/ui/defs/: id = the spot id: the stall's
   shop id, the sabil's place id, "workbench"; offset Vector3 from the spot's global position to the camera; look_at
   Vector3 offset from the spot; fov). Start rows: herb_stall offset (0, 1.7, 2.6) look (0, 1.2, 0) fov 40; the sabil
   place offset (0, 1.5, 2.2) look (0, 0.9, 0) fov 42; workbench offset (0, 1.6, 2.0) look (0, 1.0, 0) fov 40
   ([PLACEHOLDER]; numbers live only in content). Register the kind in ContentDB.KINDS. style.json: t_focus_zoom 0.6.
2. features/world/view/interact_focus.gd: class InteractFocus extends Node (process_mode ALWAYS). focus_open(spot:
   Node3D, shot: FocusShotDef, player: Player, screen_id: StringName, args: Dictionary) -> UiScreen (await it):
   a. world_cam = spot.get_viewport().get_camera_3d(); player.set_active(false); eat all input in _input while easing.
   b. Make its OWN Camera3D (child of spot's parent), copy world_cam.global_transform and fov, make_current().
   c. Tween (TWEEN_PAUSE_PROCESS, ease in-out sine, t_focus_zoom) position to spot.global_position + offset, the basis
      to look_at(spot.global_position + look_at), fov to shot.fov.
   d. Screens.open(screen_id, args); on that screen's `closed`, tween back to world_cam's CURRENT transform and fov
      over t_focus_zoom, then world_cam.make_current(), free the own camera, player.set_active(true).
   It never writes world_cam (follow_camera_rig keeps driving it underneath) and never touches the rig.
   A missing FocusShotDef -> open the screen at once with no ease (log nothing; tests cover it).
3. Hooks (smallest edits): StallSpot._interact, SabilSpot.open_screen (the sabil question and its slot picker stay as
   today: focus wraps only the first screen and eases back when the last one closes) and the workbench open path
   (where WorkshopSpot.opened is connected: grep "workshop.opened") call InteractFocus instead of Screens.open.
   One InteractFocus per area, made where the spots are made (area_actors.gd builds the spots: add one line there).
4. Interact during an ease, or a second spot pressed, does nothing.

## Do NOT edit
`features/world/logic/follow_cam.gd`
`features/world/view/follow_camera_rig.gd`
`features/world/defs/camera_rig_def.gd`
`features/world/defs/place_def.gd`
`content/world/`
`features/world/logic/framed_shots.gd`
`features/world/rooftop/rooftop_camera.gd`
`features/world/rooftop/rooftop.gd`
`features/world/interact/door_spot.gd`
`features/combat/`
`features/ui/view/screens/`
`features/puzzles/`
`docs/DECISIONS.md`
`HANDOFF.md`
`*.import`
Also leave the tests of those files alone. The workbench now sits in the tayramana room (features/world/interior/):
hook only the existing workbench open path, one line.

## Tests (features/world/tests/test_interact_focus.gd)
After focus_open the current camera is the focus camera at spot + offset (after t_focus_zoom of process frames) with
the shot's fov; the screen opens only after the ease; input during the ease is eaten and the player inactive; on
close the world camera is current again and the focus camera freed; the world camera's transform is never written;
a spot without a FocusShotDef opens the screen at once; the sabil's two-screen flow eases back once, after the last.

## Proof
`bash tools/check.sh` raw last 15 lines; renders C:/dev/game/inbox/focus_stall.png, focus_sabil.png,
focus_bench.png from the end of the ease (a .tscn wrapper, non-headless); small WIP commits; final message ends with
`Built-by: <model> (opencode)`.
