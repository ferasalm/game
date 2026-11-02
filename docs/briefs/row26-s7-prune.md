# Brief: row26-s7-prune (cf DeepSeek low with a Pattern; Python only, RUN_KIND=py)
You are in your own worktree on branch oc/row26-s7-prune (made from origin/worktree-row26-pipeline-v2; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/free_mb.py, tools/kill_tree.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-02 (asked and agreed): `claude plugin list` shows kaizen@kaizen eight times, two for worktrees that no longer exist; a local-scope plugin install is keyed by project path and nothing cleans the registry when merge_run removes a worktree. Pillar served: none directly (tool hygiene).

## Read first
tools/test_plugin_prune.py (the red tests, read-only: they define the contract), tools/free_mb.py (the house style for a small CLI).

## What to build
`tools/plugin_prune.py` (<= 90 lines, functions <= 40 lines, a docstring first):
1. `--file PATH` (default `~/.claude/plugins/installed_plugins.json`, expanduser), `--apply` flag.
2. The file is JSON {"version": n, "plugins": {name: [entry, ...]}}. An entry is dead when it has a `projectPath` and `os.path.isdir(projectPath)` is false. An entry without projectPath (user scope) is never dead.
3. Without --apply: print `dry run:` then one line per dead entry (plugin name, scope, projectPath) and `nothing changed`; exit 0, touch no file.
4. With --apply: copy the file to `<file>.<UTC yyyymmddThhmmss>.bak` first, then write the JSON back (indent 2, `newline="\n"`, keys in the original order) with the dead entries removed; a plugin left with no entries is dropped; print what was removed; exit 0.
5. A missing or unparseable file: print an error naming the path, exit 2. Never write when nothing is dead.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
none

## Ripple
none: a new stand-alone tool; nothing imports it. docs/MAP.md refreshes itself (map.py).

## Pre-mortem
none: a new tool with a dry-run default; the test fixture lives in a temp dir and never touches the real registry.

## Tests
- tools/test_plugin_prune.py :: every test (red on the base: the script does not exist)

## Checklist
- file: tools/plugin_prune.py
- has: tools/plugin_prune.py :: main
- test: tools/test_plugin_prune.py :: test_apply_removes_only_dead_paths_and_keeps_a_backup

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash low (opencode)`.
