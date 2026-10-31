# Brief: research-lookups (research; two new docs; HANDOFF row 18)
You are in your own worktree on branch gemini/research-lookups (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (Ops has no research persona; our rules outrank its text).
Timebox: 30 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Two small web lookups from the department research queues (docs/WORKFLOW.md, Research protocol). Characters and crowd need bases once the Rodin
credits end, and acceptance L3 wants lights on baked sprites. Pillar served (docs/VISION.md): Living Old Sana'a.

## Read first
docs/research/opensource-candidates.md (the format of a verified row).

## What to build
Use your browser or web tool. Read each page; never write from memory. Each doc starts with the line
"Unverified research (D18): ideas, not facts. Read 2026-10-31." and ends with a "## Sources" list of the URLs you opened.
1. docs/research/art/2026-10-31-cc0-base-meshes.md. Question: which CC0 or other game-safe libraries hold a stylised male and female human base mesh
   usable for a Middle Eastern character (robe, thobe, headwear or a plain body to dress)? A table, one row a mesh or pack, at most 10 rows:
   name | URL | licence as read on the page | polygon count | rigged yes or no | formats | fit for us in 6 words.
   Search at least Quaternius, Kenney, Poly Pizza, Poly Haven, Sketchfab (filter CC0 or CC-BY, downloadable), OpenGameArt, Blender Studio, MakeHuman. A page you could not open: the licence cell reads
   "UNREAD: <why>". Never guess a licence. Add "## Pick": the best 2 rows, one line each, and say if nothing fits.
2. docs/research/art/2026-10-31-sprite-normal-lights.md. Question: how do 2D games light pre-rendered sprites with normal maps in Godot 4 (CanvasTexture + PointLight2D)? Cover in short sections:
   setup steps from the Godot 4 docs; how a normal map is baked from a 3D model (Blender) and which axis convention Godot expects; flipped or mirrored sprites and their normals; light masks and
   shadows (LightOccluder2D) in isometric scenes; performance limits on the Mobile renderer (lights per item, batching); known bugs in 4.4 or later, with issue links. Each claim names its source.
   End with "## For us": 5 steps at most for a prison-roof scene with 2-3 moving lights.
Each doc stays under 80 lines.

## Do NOT edit
D6 defaults apply. Change nothing except the May edit files.
`.claude/`
`content/`
`features/`

## May edit
`docs/research/art/2026-10-31-cc0-base-meshes.md`
`docs/research/art/2026-10-31-sprite-normal-lights.md`
`docs/MAP.md`

## Ripple
none: research notes; nothing imports from them (assets need a manifest entry and Claude's check first). `git add` the new files, then `python tools/map.py`, before your first check.

## Pre-mortem
- A licence copied from a search snippet, not read: each row names the page it was read on; Opus opens 2.
- CC-BY shown as CC0: the cell quotes the page's wording.
- A fix from an old Godot 3 page: each Godot claim names its version.

## Tests
None new (docs); check.sh --no-godot must still pass.

## Checklist
- file: docs/research/art/2026-10-31-cc0-base-meshes.md
- file: docs/research/art/2026-10-31-sprite-normal-lights.md
- has: docs/research/art/2026-10-31-cc0-base-meshes.md :: Unverified research (D18)
- has: docs/research/art/2026-10-31-sprite-normal-lights.md :: ## For us

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
