# Lessons archive (lookup only, never loaded; first section 3D-only, moved 2026-10-25 when 3D was archived, tag 3d-archive)

- Lathe garments: torso pieces end at the waist over pelvis pieces raised 0.15 m; coats split at the pelvis (2026-10-22).
- Rodin glb: centred feet, other bone axes, stale buffers, props baked into the body -> tools/rodin (LOD indices, glb
  rewrite: lift, strip, --press) and PoseFollow (runtime retarget) (2026-10-22).
- Foot heights after seek in a SceneTree script: set bones from the tracks, compose get_bone_pose up the parents.
- SurfaceBuffer boxes have no bottom face -> lids need a tilted lining part (2026-10-23).
- Play-camera traps: a keeper behind his stall hid under the awning (StallKeeper: counter end); the follow camera
  sat 8-10 m back leading along the facing (lead along the view direction) (2026-10-23).
- A new area reusing the old mist ids drowned its lower roofs in fog -> mist per area, >= 2 m below its lowest floor
  (2026-10-23).
- Headless MultiMesh returns identity transforms -> keep them in node meta for tests (2026-10-21).
- load() of a painted .webp returns null: assets/textures/painted/ is .gdignore -> Image.load_webp_from_buffer
  (PaintedMaterials, ModelMaterials.load_texture) (2026-10-23).
- Night billboards with the moon behind go black -> min_light floor; Label3D in fog -> label_energy > 1, no alpha cut.
- Storm rain at 1.5 cm streaks was sub-pixel, and a lightning light barely shows through the painted shaders ->
  2.4 cm streaks and a screen wash (storm.json) (2026-10-23).
- set_exploring(false) hides the player and patrols -> talks use rooftop.freeze_actors (2026-10-22).
- Painted Flow art pixelized muddy -> pixelize.py --contrast 1.3 --saturation 1.5 --outline; check facing first.

## Archived 2026-10-27 (P3)
- OpenRouter :free = 50 requests/day under $10 bought credit, shared by Inkling and all :free models (2026-10-23).
- Inkling on balance-gear hit permission rejections, committed nothing -> empty `git diff base...branch`: rerun on agy (2026-10-23).
- opencode "Free usage limit reached" (GLM, DeepSeek share it) then `opencode run` hangs -> read ~/.local/share/oc-cli/opencode/log, kill the CLI's PID only (OpenCode.exe is the app) (2026-10-23).
- With an OpenRouter key opencode chose a PAID title model -> small_model pinned :free; laguna is missing from opencode's catalogue; Inkling :free works only inside agents (403 on the MCP) (2026-10-23).

## Enforced by a test or a loaded rule (moved from docs/LESSONS.md 2026-10-28, D9 triage; the check is the rule now)
- Builders sat idle (0 agy runs 10-27): nothing asked a queue row for a lane -> doc_check requires one (tools/test_doc_check.py test_queue_rows_need_a_lane) (2026-10-27).
- Finished worktrees are often detached: a listing by branch missed them -> tools/status.sh reads `worktree list --porcelain` HEADs (tools/test_status.py) (2026-10-27).
- tools/slots.sh counted 0 runs from a worktree -> it finds C:/dev/game-wt from any worktree (P1.2, tools/test_slots.py) (2026-10-27).
- The SessionStart hook read the main checkout, then ran main's stale copy ("main is 12 behind" in a level worktree) -> it reads cwd from the hook's stdin JSON and runs that checkout's copy (tools/test_session_start.py) (2026-10-27/28).
- A hook's settings.json matcher and its own regex are two lists: generate_3d slipped past both -> tools/test_pre_spend.py test_settings_matcher_reaches_every_paid_tool (2026-10-28).
- content/ is game data: an unknown kind breaks boot and every test (a pipeline list nearly went there) -> tools/test_content_kinds.py, whose FAIL says keep non-game data out of content/ (2026-10-28).
- A pull into C:/dev/game without an import left a stale class cache -> CLAUDE.md: `bash tools/sync_main.sh` after every pull (2026-10-24).
- "One session owns git in C:\dev\game; others message it" -> superseded by D10: no chat runs git there, worktrees only (2026-10-27).
