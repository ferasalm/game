# Brief: m1-archive (nv DeepSeek non-reasoning for the moves + high for the fixes; RUN_KIND=godot)
You are in your own worktree on branch oc/m1-archive (made from origin/m1-archive-base: m1-view merged; pushed). Follow GEMINI.md,
including <review_misses>. Load the builders skill.
Pattern: docs/archive/3d-reuse.md (how the 3D archive was recorded)
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 10-28: archive the turn-based battle code once the real-time fight replaces it, so the repo has one combat. Audit
docs/audits/2026-11-02-integrity.md section 2 lists exactly what goes (archive) and what stays (leave). Pillar served: 4
small, dense game (no dead combat code); integrity.

## Read first
docs/audits/2026-11-02-integrity.md section 2 only. Tag first (the head does it): `turn-based-archive` on the base commit, pushed;
a deleted file is restored with git show turn-based-archive:<path>.

## What to build
0. The head (not the builder) first writes docs/archive/turn-based-manifest.txt, one path per line, from
   python tools/res_graph.py --list tests|tools|unused --prefix features/combat (and features/neon/battle, content/combat,
   localization) on the m1-view merge, minus the audit's leave files (section 2: combatant_def, action_def, encounter_def,
   combatants.json, actions.json, encounters.json) and anything a kept screen still reaches. The audit list is a floor, not the set.
1. Delete exactly the manifest's files and the tests that name them (the combat folder, the on-map battle folder, battle content
   and CSVs, tools/shot_neon_battle). Nothing else.
2. Remove their kinds from core/content_db.gd and any preload; remove autoload or EventBus lines only they used (battle_requested
   and the battle_* signals if no listener remains; grep first, EventBus keeps live signals).
3. Keep (audit "leave"): combatant_def, action_def, encounter_def, combatants.json, actions.json, encounters.json. If a kept file
   references an archived class (vfx_def), make the smallest edit that keeps it loading (drop the vfx field check) with a test.
4. Fix every reference found by `python tools/doc_graph.py` and `bash tools/check.sh`: MAP.md and DOCMAP.md regenerate; the
   docs/design/systems-map.md rows "combat rule" and "scene" lose the turn-based files; list any doc left stale in the report.
5. Write docs/archive/turn-based-reuse.md (<= 30 lines): what was archived, the tag, what the real-time fight reuses.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`features/fight/`
`content/fight/`

## May edit
`features/combat/`
`features/neon/battle/`
`content/combat/`
`content/neon/battle_view.json`
`localization/battle.csv`
`localization/neon_battle.csv`
`tools/shot_neon_battle.gd`
`tools/shot_neon_battle.tscn`
`core/content_db.gd`
`core/event_bus.gd`
`docs/design/systems-map.md`
`docs/MAP.md`

## Ripple
Everything in the audit's archive list plus the tests that name those files (python tools/ripple.py lists them; they are
deleted with their subject, never edited to pass). The progression, items and pause menus read combatants and actions: they stay
green. Localization keys of deleted CSVs must not be referenced by a kept file (test_text_db and a grep).

## Pre-mortem
Player: a kept screen loses a dependency -> check.sh runs every UI test. Gate: a class_name vanishes and Godot says "Could not find
type" in a kept file -> run_godot.sh --import then check.sh, read the FAIL lines. Review: a test deleted to hide a failure -> the
diff lists each deleted test with its subject file; only archive-list subjects are allowed.

## Tests
- features/fight/tests/test_archive_clean.gd :: none of the archived class names or paths appears in any kept .gd, .tscn, .json,
  .csv; content_db has no archived kind; the roof boots and a scripted fight still wins.
- player-visible: unchanged: the m1-view frames before and after are identical (frame_score equal).

## Checklist
- file: docs/archive/turn-based-reuse.md
- test: features/fight/tests/test_archive_clean.gd :: test_no_archived_reference

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash (opencode)`.
