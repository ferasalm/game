# Chat brief: finish the 3D archive + rename zayd -> rydan (Feras 2026-10-27, decisions-log)
Model: Opus. Effort: high. One chat. Restore anything from tag `pre-cleanup` (pushed). Drafts from the first chat:
docs/briefs/archive-cleanup/res_graph.py.txt (static res:// + class_name graph) and save_v7_migration.patch.txt.

## Done (stage 1, on main)
Old models + textures archived: zayd, bilqis, abu_nabil, concession_enforcer, survey_drone (glb, t_*.png, painted
skins, bake.json), models.json keeps rydan + roya; manifest; art tests moved to rydan/roya;
abu_nabil speaker has no sprite (stand-in portrait). Kept on purpose until the rename: zayd_* and old bilqis_* portraits (menus and dialogue load them by path; decide: bilqis -> bilqis_ng portraits?).

## Stage 2: dead files and docs
- `nonexistent_dir_for_b5/` is written into the repo by a test: find the test, point it at `user://` or a temp dir, then
  delete the folder (root cause, not the file).
- Dead scripts (static graph, confirm with check.sh): features/dialogue/view/dialogue_demo.*, features/equipment/view/
  equipment_detail.gd + equipment_item_button.gd + grid_disc/hologram .gdshader, features/jambiyah/defs/heirloom_def.gd,
  logic/stat_row.gd + workshop_stats.gd, features/puzzles/defs/puzzle_yard_def.gd. Paths built at runtime (portraits,
  ui_bg .gdignore webp) are invisible to the graph: never delete on its say-so alone.
- Docs: Qarnaw and 3D-only design docs + old 3D briefs (level1-*, camera-*, souq-*, interact-focus*, holo-map*,
  tayramana*, storm, rooftop-v2, render-clean*, cyber-look, menus-equip-fix*) -> docs/archive/; then grep HANDOFF,
  LESSONS, docs for the moved paths; `python tools/map.py`.
- res_graph.py -> tools/ scoped to features/ core/ content/ assets/, a runtime-path allowlist, `--check` in check.sh,
  and tools/test_res_graph.py with one planted dead file (fails without the fix).

## Stage 3: rename (own commit)
- Collisions: speakers.json has both `zayd` and `rydan` (rydan's sprite is "zayd"): drop the zayd speaker, lines ->
  rydan. NAME_ZAYD/EPITHET_ZAYD rows -> the RYDAN keys. combatant zayd, loadout zayd_start, sound footstep_zayd,
  pixel sprite zayd, test_zayd_kit.gd, design/zayd-moves.md (cited in LESSONS, CANON) -> rydan.
- Old Abu Nabil dialogue text says "Zayd" for the hero -> "Rydan". The story officer Zayd gets his own id (officer_zayd).
- Save: apply save_v7_migration.patch.txt (VERSION 7, LEGACY_HERO, _v6_to_v7 renames party, xp, vitals, "zayd.*" keys);
  do not edit the old fixtures (save_v3/v5.json): add a test loading save_v5.json -> rydan everywhere.
- Guard test: no `zayd` id outside the migration, its fixtures and docs/archive; probe it with one planted id.
- Then archive zayd_* portraits (rydan_* exist). CANON line 14 -> done. Ripple: open branches in ../game-wt (3D, paused)
  and RPG + menus polish briefs will conflict on zayd paths: note it in HANDOFF.
- review-code on the diff, check.sh, merge, /handoff.
