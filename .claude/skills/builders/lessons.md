# Builder lessons (seed: docs/LESSONS.md section 4; add dated lines here, keep <= 40)
- One worktree per builder; registries (ContentDB KINDS, MAP.md) conflict: keep both sides, regenerate MAP.md (2026-10-21).
- Builders said "done" with failing tests or died mid-edit: build_pipeline.sh keeps leftovers as WIP, checks, one free fix pass; PASS with no commits = nothing built (2026-10-23).
- agy passes check.sh yet misses what a player sees: GEMINI.md review_misses + player lens on renders (2026-10-22).
- agy is not creative: briefs give geometry recipes with numbers, colours and the concept path (2026-10-23).
- A builder rewired a signal and its old listener went dead: Ripple lists every listener/key/id; review-code greps them (2026-10-24).
- Silent stdin hangs (agy, opencode, ffmpeg): `< /dev/null`, `-nostdin`, child timeouts; check background jobs at their expected end (2026-10-25).
- Editing a running .sh broke the running copy: never edit tools/*.sh mid-run (2026-10-23).
- Fork from origin/<base>: push the base before a launch (a fix run started on old code) (2026-10-26).
- Free calibrated lens: nemotron-3-ultra :free found 6/6 planted defects; free models failed the reader gold set (2026-10-27).
