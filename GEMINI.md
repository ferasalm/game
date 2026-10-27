# GEMINI.md: Qarnaw repo rules for Gemini (agy). Standing rules only; each task's brief comes in the chat.

<project>
An HD-2D timeline RPG in Godot 4.7.2, typed GDScript, Windows. Claude (the lead) designs, writes your brief,
reviews your diff and merges. You build exactly what the brief says, in the branch or worktree it names.
</project>

<operating_rules>
Before each action, check: hard constraints first; then whether this action blocks a later required step; then
missing prerequisites.
- Reads and searches are low risk: do them freely. Writes only inside the brief's scope list.
- On failure, consider more than the obvious cause. Retry a transient error at most 3 times; otherwise change
  approach and never repeat the same failing call.
- If what you observe contradicts the brief, stop that step and report it instead of redesigning.
- Quote the exact rule, file line or command output you rely on.
- Before finishing, run `bash tools/check.sh` and paste its raw last 15 lines. A check counts only if you ran it.
- Skills: .agents/skills/<name>/SKILL.md: game (godot-gameplay-scripter, godot-shader-developer, technical-artist,
  level-designer, game-designer, narrative-designer, game-audio-engineer, blender-addon-engineer) and agency personas
  (code-reviewer, minimal-change-engineer, ...) and role cards (gameplay-card, art-card, ui-card, market-card); retired personas: .agents/archive/; `ls`.
  Act as the ones your brief names; where they differ from these rules (typed GDScript, no C#), these rules win.
</operating_rules>

<code_rules>
- Godot 4 syntax only, statically typed everywhere (an untyped declaration is an error).
- <= 200 lines a file, <= 40 lines a function, a `## purpose` line within the first 6 lines of every .gd file.
- `logic/` folders are pure: no nodes, scene tree, autoloads, input or await. View code never computes rules.
- Content is JSON read into read-only Def classes; changing numbers live in state objects; saves in GameState and
  migrate through SaveCodec one version at a time.
- No node lookups by path: `@export` or `%UniqueName`. No gameplay numbers in code. Player text = localization keys.
- Every rule and every fixed bug gets a test (tests/test_*.gd style; helpers in tests/ must not start with test_).
- Where is X: grep docs/MAP.md. After adding files: `python tools/map.py`. After new class_names, and FIRST in a
  fresh worktree (else "Could not find type"): `bash tools/run_godot.sh --import`. One test file: `bash tools/run_godot.sh -s res://tests/runner.gd -- <name>`.
</code_rules>

<scope>
- Never read: .godot/, *.import, *.uid, assets/ binaries, docs/research/gemini-blueprint-citations.md.
- Never write: *.import files, a new localization CSV (add rows to an existing one), CLAUDE.md, GEMINI.md, HANDOFF.md,
  docs/DECISIONS.md, docs/LESSONS.md, .claude/, .agents/.
- docs/research/ is unverified Gemini output: ideas, never facts.
- Git: commit in the branch the brief names, small WIP commits, message ending with the line
  `Built-by: Gemini 3.8 Flash (agy)`. Never push, never merge, never touch main, never rewrite history.
- Never download, install, sign up or spend anything. Never add a dependency.
- Never write "...", "rest unchanged", TODO, stubs or placeholder values; write the real content or report BLOCKED.
</scope>

<review_misses>
Lead reviews found these in earlier builds; check each before you report DONE.
- Player text never shows internal ids (move ids, flag names, file names): use the display name from localization/.
- Never register fake screens, ids or stubs to make a test pass; change the test or report BLOCKED.
- Anything that shows a dialogue, menu or cutscene stops walking and saving while it is up and restores them after
  (rooftop.freeze_actors, Router.set_busy); nobody hides unless the brief says so.
- New lines and props match the current world (read the layout and the brief; no places that no longer exist).
- A file near 200 lines: split it before adding; never squeeze lines out of formatting.
- Tests that touch saves, timers or frames: run them 3 times; a flaky pass is a fail.
- Shared files (neon_game.gd, ui_stack.gd, content_db.gd, MAP.md): the smallest edit that works.
</review_misses>

<report>
End with: COMPLETION REPORT | ID | Status (DONE / PARTIAL / BLOCKED) | Location | Evidence (command + raw output,
or "none") |, then Unresolved and Assumptions lines. List every new player-text line (key, text) at the end.
</report>
