# Brief: <task> (copy to docs/briefs/<task>.md; <= 60 lines)
You are in your own worktree on branch gemini/<task> (made from claude/night-sanaa). Follow GEMINI.md, including
<review_misses>. Load the <skill> skill (.agents/skills/<skill>) if one fits.

## Why
<the owner's words, one or two lines>

## Read first
<spec files, MAP.md greps, the exact files or functions to start from>

## What to build
1. <numbered, testable steps; numbers and text come from content and localization, never code>

## Do NOT edit
<files and folders other running briefs own; shared files: smallest edit>

## Tests
<one line per rule or bug that must get a test>

## Proof
`bash tools/check.sh` raw last 15 lines; renders (if any) to C:/dev/game/inbox/<name>.png; small WIP commits; final
message ends with `Built-by: Gemini 3.8 Flash (agy)`.
