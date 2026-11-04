# Project overlay (row 28 part g): the only project text a builder gets beside its brief
The personas under .agents/skills are stock agency-agents text (MIT, .agents/skills/AGENCY-LICENSE). Where a persona
differs from this page or from the brief, the brief wins, then this page, then the persona.

## The game
Neon Glitch: a 2D isometric action RPG with real-time Hades-like combat and a linear story in a cyberpunk Old Sana'a.
Combat feel wins every tie (docs/VISION.md). Names, story, art direction: docs/CANON.md (read before content work).
Decisions in force: docs/DECISIONS.md. Where is X: grep docs/MAP.md, not `ls -R`.

## Code
Rules and Godot traps: .claude/rules/code.md (pasted into your prompt after this page). In short:
- Godot 4 with static types everywhere; no web stacks, no C#; version pinned in docs/DECISIONS.md.
- A file is 200 lines at most, a function 40; folders named logic hold no nodes, input or await.
- Gameplay numbers live in content JSON read by Def classes, never in code. Player text goes through TextDB keys.
- Every rule and fixed bug gets a test; run `bash tools/check.sh` and paste its raw last 15 lines.
- Stay inside the brief's May edit list; never write *.import files, .claude/, .agents/ or the decision docs.

Role-specific project rules (shaders, Blender tools, levels, narrative, audio, UI states): docs/design/persona-rules.md.

## Output
Follow the persona's checklists and output template only as far as the brief asks. Report DONE with the check output,
or BLOCKED with the exact reason. Never invent a stub to turn a test green.
