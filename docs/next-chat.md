# Next chat: Row 4, Opus high (head of the M1 build)

Paste from HANDOFF.md ("Prompt for the next chat"): `claude --model opus -w <name>` (not opusplan: it executes on Sonnet outside plan mode, 11-04), `/effort high`, auto mode, then the one-line pointer.

## Where it stands (2026-11-02)
- Row 3 is done: the M1 brief set is written. Read docs/briefs/m1-plan.md first (waves, workers, gates), then the spec
  docs/design/m1-fight.md and the shared types docs/design/m1-fight-api.md. ARCHITECTURE section 8 is already rewritten.
- Feras decided (decisions-log 11-02): move, dash, 3-hit combo, parry with posture and a dash-counter; soft aim; floating
  stick + buttons; baton + rifle guards. Special and cast are out of M1. Numbers are [PLACEHOLDER], tuned by the harness and play.
- Red tests are NOT written yet: a wave's tests need the previous wave's types, so each wave starts with its scope run.
- Pipeline: the low-cost-pipeline skill (Resume, Plan a batch, Flow of one part). The row 26 writer trial (agy vs nv, real cost) rides on these builds.

## Do
1. `bash tools/status.sh`, `bash tools/slots.sh`; Wave 1 = m1-defs: critic read of the brief, scope run for its red tests (GDScript:
   the scope template is Python-shaped, adapt it; ask Feras if stuck twice), READ EVERY TEST, lock_tests.sh, build, part_report, cross_review, merge.
2. Per later wave: run `python tools/parts_plan.py` on that wave's briefs, then the same loop. Wave 6 first needs the head to write docs/archive/turn-based-manifest.txt.
3. After the build: harness table read by the head, eye gate, review-player, review-feras, Android export in CI (D17), then row 5.

## Rules
- Stuck or refused: ask Feras with AskUserQuestion, options with a pick. Never `/advisor` unasked. A Sonnet subagent only at `high` (Feras 11-02).
- A rule change (not a number) goes to Feras with a pick; a failing balance band is fixed in content/fight/, never by loosening the band.
