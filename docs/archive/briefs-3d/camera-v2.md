# Brief: camera-v2 (<= 60 lines)
You are in your own worktree on branch gemini/camera-v2 (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Load the godot-gameplay-scripter skill (.agents/skills/godot-gameplay-scripter).

## Why
Owner (DECISIONS 2026-10-23): "close third-person follow with a wide view outdoors (Brothers: A Tale of Two Sons),
semi-fixed framed shots indoors". Refs: inbox/camera-refs/ (outdoor: camera ~6 m behind and above the pair, they
stand in the lower third, the land opens ahead; indoor: a fixed corner shot of a staged room, the hero small in it).

## Read first
docs/MAP.md lines for explore_camera, rooftop_camera, camera_rig_def, camera_preset_def, camera_limits,
occlusion_fade, player.gd; content/world/camera.json; features/world/rooftop/rooftop_world.gd and rooftop_shot.gd.

## What to build (every number in content/world/camera.json, never in code)
1. Pure logic `features/world/logic/follow_cam.gd` (class FollowCam): from focus (player 0.7 + follower 0.3), the
   move direction, delta and a manual orbit input, it returns yaw, pitch, distance, fov and the aim point.
   Defaults: distance 6.5 m, pitch 28 deg down, fov 50, aim = focus + 1.2 m up + 1.5 m along the facing (wide view
   ahead). Lazy yaw: after 0.8 s of steady movement the yaw eases (0.6 rad/s max) to sit behind the move heading;
   never while walking toward the camera (dot < -0.3); manual orbit (actions camera_left / camera_right: Q/E and
   the right stick; add them to project input map) wins and pauses auto-yaw 2 s.
2. Camera zones: AreaDef places of type "camera_zone" (rect x/z, yaw, pitch, distance, fov); inside one the rig
   eases (1.2 s) to its numbers and auto-yaw stops. One zone in the current rooftop area as an example.
3. Collision: the arm shortens to a ray hit on walls (min 2 m) so the camera never enters a wall; occlusion fade
   stays on.
4. Player input becomes camera-relative (rotate the input vector by the camera yaw) in follow mode.
5. Indoor framed mode, pure logic `features/world/logic/framed_shots.gd` (class FramedShots): a room has a list of
   shots (camera position, base look target, an x/z rect where it is active). Picks the shot whose rect holds the
   player, with 0.5 m hysteresis; cuts instantly; the camera turns to keep the player framed, clamped to +-15 deg
   from its base look. Input basis: keep the previous shot's basis while the stick direction stays the same
   (within 20 deg), switch when it changes (no flip at a cut).
6. A view node `features/world/view/follow_camera_rig.gd` that drives the Camera3D with either mode; Rooftop uses
   follow mode when content/world/camera.json "mode" is "follow" (set it so). Keep the old ExploreCamera code
   working for "mode": "fixed" (the intro shot may stay as it is).
7. A grey-box test room `features/world/interior/camera_room.tscn` + script (8 x 5 m floor, 3 m walls with two
   window gaps, a low bench, two shots: door corner and window corner) to show the framed mode; built in code from
   numbers in content/world/camera.json "test_room".

## Do NOT edit
features/combat/, content/combat/, localization/combat.csv, features/items/, content/world/areas.json beyond one
camera_zone entry, docs/design/, HANDOFF.md, docs/DECISIONS.md.

## Tests
FollowCam: defaults, lazy yaw delay and rate, no turn when walking at the camera, manual orbit pause, zone blend;
FramedShots: shot pick, hysteresis, clamp, basis kept until the stick turns; input rotation by yaw; arm shortening.

## Proof
`bash tools/check.sh` raw last 15 lines; renders (not headless, LESSONS 2): the rooftop in follow mode from 2 spots
and the test room from both shots, to C:/dev/game/inbox/camera_v2_*.png (960x540); small WIP commits; final
message ends with `Built-by: Gemini 3.8 Flash (agy)`.
