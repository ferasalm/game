# Brief: <task> (<worker and effort>; <language>, RUN_KIND=<py|godot>)
You are in your own worktree on branch oc/<task> (made from origin/<task>-base, the locked tests; pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: <1-3 real repo files to copy; the pipeline pastes them>
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
<the owner's words, one or two lines>. Pillar served (docs/VISION.md): <one pillar; combat feel wins ties>.

## Read first
<the locked test file (read-only), the exact files and functions to start from; read nothing else>

## What to build
1. <numbered, testable steps with exact names, paths and outputs>

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
<one backticked path per line for anything else>

## May edit
<backticked files the task must touch, INCLUDING the existing tests python tools/ripple.py lists, each with its reason in Ripple>

## Ripple
<every listener, key, id, test fixture and doc this change touches, each with how the build keeps it working>

## Pre-mortem
<three lines: how it fails for the player, in the gate, in review; what in this brief stops each>

## Tests
- <locked test file> :: every test (red on the base)

## Checklist
- file: <path>
- test: <test file> :: <name>

## Proof
`bash tools/check.sh --no-godot` (or the full check) raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
