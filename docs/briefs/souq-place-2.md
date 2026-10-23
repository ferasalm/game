# Brief: souq-place (<= 60 lines; main holds the level-1 blockout; souq-props-2 is reviewed, unmerged)
You are in your own worktree on branch gemini/souq-place-2 (made from claude/level1-review: main + tayramana + camera-wall). Follow GEMINI.md, including
<review_misses>. Load the level-designer skill.

## Why
Feras: the sabil stands against a wall on the market roof R2 with its Musnad sign on that wall (no floating signs),
and the crates keep clear of Abu Nabil. The second props pass (sabil wall niche, herb stall) is built on its own branch.

## Read first
docs/design/level-1.md (R2, the market roof); C:/dev/game/inbox/level1_concept_sabil.png and level1_concept_roofs.png
(look only); content/world/areas.json item souq_rooftops_v4 (props, places sabil / shop_herbs / herb_seller, buildings
tower_r2); content/world/props.json items sabil and herb_stall; the old area souq_rooftops's "signs" entries and
features/world/defs/area_def.gd SignSpec (how a Musnad sign is placed); tools/musnad.py (Musnad text);
tools/shot_level1.gd and tools/shot_prop.gd (render tools).

## What to build
1. `git merge gemini/souq-props-2` first. Conflicts: content/world/props.json takes souq-props-2's sabil and herb_stall
   items and keeps every other item from main; docs/MAP.md: regenerate with `python tools/map.py`. Commit the merge.
2. Sabil on R2: move the sabil prop and its "save" place so the sabil's own back wall stands flush against R2's
   parapet or a wall on R2 (back face <= 0.05 m from it, facing into the roof), reachable on the walk graph, >= 3 m from
   the herb stall. Keep the place 2 m in front of the basin, facing it.
3. One Musnad sign on that same wall above the niche (SignSpec in souq_rooftops_v4 "signs"; text from tools/musnad.py,
   the word for "sabil" or "water"; no Arabic script, no English). Its back <= 0.05 m from the wall: nothing floats.
4. Crates and barrels of the herb stall (props.json parts or area props) stay >= 1.5 m from the herb_seller place;
   move crates, never Abu Nabil.
5. Numbers live in content only; no code change is needed (if one is, keep it <= 20 lines and say why).

## Do NOT edit
`features/combat/`
`features/puzzles/`
`features/world/logic/`
`features/world/view/follow_camera_rig.gd`
`features/world/interact/`
`content/world/storm.json`
`content/world/camera.json`
`docs/design/`
`HANDOFF.md`
`docs/DECISIONS.md`

## Tests (features/world/tests/test_souq_place.gd)
The sabil's back is within 0.05 m of a wall or parapet on R2 and its save place is walkable; the Musnad sign's back is
within 0.05 m of the same wall and its text is Musnad only; every crate or barrel is >= 1.5 m from herb_seller.

## Proof
`bash tools/check.sh` raw last 15 lines with 0 failed; renders from the play camera (a .tscn wrapper like
tools/shot_level1.tscn, non-headless, 960x540): C:/dev/game/inbox/souq_r2_sabil.png (party 3 m in front of the sabil)
and C:/dev/game/inbox/souq_r2_stall.png (party at the stall, Abu Nabil in frame); small WIP commits; final message ends
with `Built-by: Gemini 3.8 Flash (agy)`.
