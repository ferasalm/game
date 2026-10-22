# Brief: architecture audit (read-only)
You are in your own worktree on branch gemini/architecture-audit (made from claude/night-sanaa). Follow GEMINI.md.
Work as the Software Architect and Codebase Archaeologist agents would. Do not change any code or content.

## Why
The owner wants the game built as "many short buildings on a large surface, not one tall tower": features that stand
alone, can be reused, changed or swapped (even gameplay or genre) without breaking the rest, and never contradict
each other. Find where the code falls short of that, cheaply fixable first.

## Read
docs/ARCHITECTURE.md, docs/MAP.md, docs/DECISIONS.md, project.godot (autoloads), core/, then features/* (grep before
reading; never whole folders at once).

## Check, each with file:line evidence
1. Coupling: a feature that references another feature's internals (class_names, node paths, content kinds) instead of
   its public signals, EventBus or core ports. List each cross-feature reference and whether it is allowed by
   ARCHITECTURE.md.
2. Swap test: what would break if combat (timeline battles) were replaced by another battle system, or exploring by
   another genre's field mode? Name the seams that exist (BattleSession, AreaPort, Router) and the ones missing.
3. Autoloads and globals: what each one owns; any that hold rules, or that features reach into for state they should
   receive.
4. Content: rules or numbers hard-coded in code; Def classes with logic; kinds with no test of their file.
5. Saves: everything that changes during play and is not in GameState; version and migration coverage.
6. Doc drift: ARCHITECTURE.md or design docs that say something the code no longer does (and the reverse).
7. Rules: logic/ purity, file and function size, missing `##` purpose lines, untested rules (run tools/lint_gd.py and
   read its output).
8. Contradictions between DECISIONS.md lines and the code (for example the Jambiyah spelling, Musnad-only signs).

## Output
docs/audits/architecture-2026-10-22.md, at most 220 lines: a 5-line verdict, then findings ranked by risk to future
change. Each finding: evidence (file:line), why it matters for reuse or swapping, a concrete fix, its size (S/M/L).
End with the top 5 fixes in order. Commit only that file; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
No check.sh needed (no code changed); say so.
