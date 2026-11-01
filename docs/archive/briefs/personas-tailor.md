# Brief: personas-tailor (row 1 item 9 of docs/briefs/efficiency-hooks.md; <= 60 lines)
You are in your own worktree on branch oc/personas-tailor (made from origin/claude/dazzling-shannon-8d05cc). Follow GEMINI.md.
Load the narrative-designer skill only as an example of the shape you are replacing. Timebox: 45 min. First commit within
15 min (one persona per commit), then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras 10-28: the 10 personas must be tailored to Neon Glitch, "not generic". They are engine-agnostic agency text (Unity,
Unreal, FMOD/Wwise, C#) and every builder prompt pastes one. Pillar served (docs/VISION.md): combat feel wins ties.

## Read first
docs/VISION.md, docs/CANON.md, .claude/rules/code.md, docs/DECISIONS.md section "Engine and code", docs/design/art-bible.md
(the Art personas), docs/WORKFLOW.md section "## Routing" (each persona's Dept, lane and reviewer), tools/test_personas.py
(the contract). Then each .agents/skills/<name>/SKILL.md you rewrite. Nothing else.

## What to build
Rewrite these 10 files, one source each (game-designer, narrative-designer, technical-artist, level-designer,
game-audio-engineer, godot-gameplay-scripter, godot-shader-developer, blender-addon-engineer, ui-designer,
ui-finish-gate-reviewer): .agents/skills/<name>/SKILL.md. Each file, <= 8500 bytes, in this order:
1. Frontmatter: `name: <name>` (the folder name, no quotes, no agency- prefix) and `description: Use for <its jobs in
   Neon Glitch> ...` (one line, names the game's real work, e.g. roof fight tuning, Rydan's moves, Old Sana'a levels).
2. A title, then the line `Adapted from The Agency (agency-agents), MIT: see .agents/skills/AGENCY-LICENSE.`
3. `## Role in Neon Glitch`: who it is, the jobs it takes here, what it never does (decide scope, story or art: Feras does).
4. `## Our stack and rules (they outrank this persona)`: Godot 4.7.2, typed GDScript, .claude/rules/code.md, logic/ pure,
   integer 60-tick deterministic combat that returns events, read-only Def classes from content JSON, player text via
   TextDB keys, Mobile renderer + Android kept alive, 2D isometric, combat feel wins every tie. Only the lines it needs.
5. `## Canon it needs`: the VISION, CANON and art-bible lines that matter to this persona, quoted short, with file names.
6. The persona's craft: keep the best of its original method, rewritten for our game; drop every other engine and tool.
7. `## Builder limits`: edit only the brief's May edit paths; tests are read-only; numbers and text from content and
   localization; finish with the brief's Proof.
8. `## Output template`: the exact shape of what it hands back (a spec, a diff list, a review table), <= 15 lines.
9. `## Reviewer`: who reviews its work, from the Routing table (review-code, review-player, review-canon, review-feras,
   ui-finish-gate-reviewer); ui-finish-gate-reviewer itself is the UI review before Feras, reviewed by review-feras.
Never write the words Unity, Unreal, FMOD, Wwise, UE5, Blueprint or C# (the test fails on them). Then run
`python tools/sync_personas.py` (writes the .claude/skills and .claude/agents copies) and `python tools/test_personas.py`.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed: existing tests, tools/, .github/ (edits and
deletions; new test files are allowed) and every change under assets/ (incl. *.import). Keep this prose free of
backticks: every backticked token in this section is a forbidden path, and May edit does not lift it.
`.agents/skills/AGENCY-LICENSE`
`docs/`

## May edit
`.agents/skills/*/SKILL.md`
`.claude/skills/*/SKILL.md`
`.claude/agents/*.md`

## Ripple
.opencode/agent/<name>.md reads each description (tools/oc_agents.py; run `python tools/oc_agents.py` after). The
review-* agents in .claude/agents are not personas: never touch them. build_pipeline.sh pastes the source into prompts.

## Pre-mortem
A generic rewrite that only swaps engine names: each file must quote real CANON or VISION lines and name our files.
A persona that contradicts code.md (untyped code, numbers in code): the Our stack section repeats the rule.
Size creep past 8500 bytes: cut the generic craft first, never the stack, canon or template.

## Tests
tools/test_personas.py (read-only; red on the base): names, no foreign engine, Godot 4.7.2 + code.md, the Adapted from
line, Output template + Reviewer sections, <= 9000 bytes, copies in sync, drift caught.

## Checklist
- file: .claude/agents/ui-finish-gate-reviewer.md
- file: .claude/skills/ui-designer/SKILL.md
- file: .agents/skills/godot-gameplay-scripter/SKILL.md

## Proof
`bash tools/check.sh` raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
