# Brief: row25-sync-dirty (copy of docs/briefs/TEMPLATE.md headings; pipeline proof run for row 25, cf DeepSeek low)
You are in your own worktree on branch oc/row25-sync-dirty (made from origin/system-v4; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/sync_main.sh
Timebox: 15 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Two reviewers of system-v4 (DeepSeek max and GLM-5.3 max) agree: `tools/sync_main.sh` switches to main and carries a dirty tree there. Feras's rule (CLAUDE.md) is that a chat runs it only when it has no local changes. Pillar served: none directly (tooling that keeps the main checkout trustworthy).

## Read first
tools/sync_main.sh (15 lines) and tools/test_sync_main.py (the three new tests at the end are red on the base).

## What to build
1. In tools/sync_main.sh, before the branch switch, refuse when any TRACKED file has uncommitted changes (staged or not; untracked files are fine): print `SYNC FAIL dirty` as the last stdout line and exit 1, with the checkout untouched. Use `git diff --quiet HEAD --` (non-zero when tracked files differ from HEAD).
2. Keep the header comment true: add one clause saying a dirty tracked tree fails with `SYNC FAIL dirty`.

## Do NOT edit
Existing tests and tools/test_sync_main.py (locked red tests).

## May edit
`tools/sync_main.sh`

## Ripple
none: sync_main.sh is called only by hand after a merge to main (CLAUDE.md, DECISIONS D10); no listener, key or id depends on it.

## Pre-mortem
none: five-line guard in a script with a four-case toy-repo test.

## Tests
- tools/test_sync_main.py :: test_uncommitted_tracked_change_fails_on_dirty (red on the base)
- tools/test_sync_main.py :: test_a_dirty_file_a_switch_would_carry_still_fails_on_dirty (red on the base)
- tools/test_sync_main.py :: test_untracked_file_does_not_fail (green before and after)
Player-visible: none (tool only).

## Checklist
- has: tools/sync_main.sh :: SYNC FAIL dirty

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash low (opencode)`.
