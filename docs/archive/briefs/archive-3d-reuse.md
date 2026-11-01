# Brief: archive-3d-reuse (write the reuse catalogue of the archived 3D game; docs only; <= 60 lines)
You are in your own worktree on your own branch made from claude/retire-3d-6d2a28. Follow AGENTS.md. Load the
game-designer skill and the software-architect persona.

## Why
Feras (2026-10-26): "We want to learn and reuse from the 3D archives what does not contradict or conflict with our
new game." The 3D game is archived at git tag `3d-archive` (branch `archive/3d`); the working tree no longer has it.

## Read first
docs/DECISIONS.md (the rules Neon Glitch must keep), docs/design/neon-glitch-plan.md, docs/design/first-playable.md,
docs/archive/design-3d/retire-3d-audit.md. The archive: `git ls-tree -r --name-only 3d-archive -- features/world features/prototype
features/map features/puzzles/view features/combat/view content/world`, and `git show 3d-archive:docs/MAP.md` (one
purpose line per file). Read a file with `git show 3d-archive:<path>` only when its purpose line is not enough.

## What to write: docs/archive/3d-reuse.md (<= 120 lines)
1. Two lines on top: where the archive is (tag + branch), and the restore command
   `git checkout 3d-archive -- <path>` (then fix it to Neon's rules before committing).
2. A table, one row per reusable piece: | Archived path(s) | What it is | Reuse for Neon (how, in one line) | Fit |.
   Fit is one of: "as is" (pure logic, no 3D types), "port" (idea or rules good, view must be redone in 2D),
   "idea only". Look hardest at: pure logic in features/world/logic (patrol safety, safe spot, walk graph, follow
   camera maths, stall keeper, light pick), interaction rules (sabil save spot, talk spots, stall/shop flow,
   crossing, focus), the 2D Control pieces of the 3D battle HUD (item menu, numbers, end panel, hero/info cards, turn
   panel, notices), the holo map's logic and legend (for a 2D Neon map), puzzle placement, area title card, loot
   popup, weather and rain ideas, Abu Nabil's talk and shop data, level-1 layout ideas.
3. A short list "Do not reuse" with the reason each conflicts with DECISIONS (3D runtime characters, painted 3D
   diorama, perspective camera rigs, GridMap tiles, the 3D holo table...).
4. A short list of tests worth porting with the reused piece (path + what rule it guards).
Only name paths that exist at the tag (check each with `git cat-file -e 3d-archive:<path>`). Facts only from the
files; no invented numbers.

## Do NOT edit
`features/`
`core/`
`content/`
`assets/`
`tools/`
`localization/`
`tests/`
`project.godot`
`docs/design/`
`HANDOFF.md`
`docs/DECISIONS.md`
Your only new file is docs/archive/3d-reuse.md (and docs/MAP.md if `python tools/map.py` changes it). Do not restore archived files into the tree.

## Tests
- None in Godot (docs only). Every path in the table exists at the tag (you checked with git cat-file).

## Checklist
- file: docs/archive/3d-reuse.md

## Proof
`bash tools/check.sh` raw last 15 lines; one commit; final message ends with `Built-by: <model> (opencode)`.
