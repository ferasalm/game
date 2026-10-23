# Brief: camera-wall (<= 60 lines)
You are in your own worktree on branch oc/camera-wall (made from main). Follow GEMINI.md and AGENTS.md, including
<review_misses>. Load the godot-gameplay-scripter skill.

## Why
Feras (playtest, DECISIONS 2026-10-23): when a wall blocks the view, the camera rises toward an isometric view; it
never closes in on faces. Today features/world/view/follow_camera_rig.gd _shortened_camera_pos() shortens the arm
down to collision_min_distance (2 m), which puts the camera in the characters' faces.

## Read first
features/world/logic/follow_cam.gd (camera_position, pitch, shorten_arm); features/world/view/follow_camera_rig.gd
(_update_follow, _shortened_camera_pos); content/world/camera.json item "explore"; features/world/defs/camera_rig_def.gd;
features/world/tests/test_follow_cam.gd; tools/shot_level1.gd (render tool, area souq_rooftops_v4).

## What to build
1. camera.json "explore": wall_rise_max_pitch 62.0 (deg), wall_rise_step 4.0 (deg), wall_rise_up_rate 6.0 and
   wall_rise_down_rate 1.5 (per second, exponential ease), collision_min_distance 4.0. Read them in CameraRigDef.
2. FollowCam (logic, pure): camera_position(override_distance, override_pitch = NAN); a static
   rise_candidates(base_pitch, max_pitch, step) -> Array[float] (base first, then base+step ... up to max, max
   included); a wall_rise: float (radians added to pitch) eased by ease_wall_rise(target, delta, up_rate, down_rate)
   (rises fast, settles back slowly).
3. Rig: each frame, ray-test the candidates from aim to camera_position(distance, candidate) (excluding player and
   follower); the first clear one sets the target rise (candidate - pitch); none clear -> the max pitch. Ease wall_rise
   toward it; place the camera at pitch + wall_rise and full distance; only if that pose is still blocked, shorten the
   arm with shorten_arm (never below collision_min_distance). Camera zones and framed shots keep working.
4. No player camera control is added; no numbers in code.

## Do NOT edit
`features/combat/`
`features/puzzles/`
`features/world/interact/`
`content/world/areas.json`
`content/world/props.json`
`docs/design/`
`HANDOFF.md`
`docs/DECISIONS.md`

## Tests (test_follow_cam.gd; a new file if it would pass 200 lines)
rise_candidates order and end; ease_wall_rise rises faster than it falls and never passes the target; camera_position
with override_pitch; a headless physics test: a wall box between aim and the default camera -> after some physics
frames the camera is higher than its default height and at least collision_min_distance from the aim; no wall -> pitch
returns to default.

## Proof
`bash tools/check.sh` raw last 15 lines with 0 failed; renders (non-headless, 960x540) from tools/shot_level1.tscn of
R1-R5 to C:/dev/game/inbox/level1_*.png plus C:/dev/game/inbox/camera_wall.png with the party's back to R2's tallest
wall (the camera must be above, not in their faces); small WIP commits; final message ends with
`Built-by: <model> (opencode)`.
