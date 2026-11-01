# Brief: row17-licences (research; one doc edit; HANDOFF row 17 part f)
You are in your own worktree on branch gemini/row17-licences (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (Ops has no research persona; our rules outrank its text).
Timebox: 40 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
docs/research/opensource-candidates.md lists 15 repos and asset sites with licences nobody has read (row 16 left it
"not planned"). Every asset we ship needs a true source and licence (CLAUDE.md: manifest with source and licence).
Pillar served (docs/VISION.md): a small game finished fast, with no licence surprise before the Steam demo.

## Read first
docs/research/opensource-candidates.md (the whole file, 21 lines).

## What to build
1. For each table row, open its URL in your browser or web tool. For a GitHub repo: confirm it exists, open its
   LICENSE (or COPYING) file, read the licence name and copyright holder, note the last commit date and whether
   the repo is archived. For an asset site (Kenney, Freesound, Quaternius, Poly Haven): open the named page and its
   licence page and read the stated licence.
2. Edit the licence cell to what the file or page says, followed by " (verified 2026-10-30, <LICENSE URL>)". A repo
   or page that does not exist or has no licence file: delete the row and list it under a new "## Removed" section
   with the reason. Add a column "last commit / archived" for repos ("n/a" for asset sites).
3. A row whose real licence differs from the old cell: also fix its manifest source line cell to match.
4. Change the first line from "Unverified research (D18)" to "Licences read from each LICENSE page 2026-10-30
   (row 17); ideas still need Claude's check before any import."
5. Never guess a licence: a page you could not open = keep the row, licence cell "UNREAD: <why>".

## Do NOT edit
D6 defaults apply. Change nothing except the May edit file.
`.claude/`
`docs/research/model-evidence-2026-10.md`

## May edit
`docs/research/opensource-candidates.md`

## Ripple
none: a research list; nothing imports from it yet (assets need a manifest entry and Claude's check first).

## Pre-mortem
- A licence copied from the old cell, not read: each verified cell names its LICENSE URL; Opus opens 3 of them.
- Freesound is mixed per sound: the cell keeps "per sound; CC0 or CC-BY only".
- A renamed or moved repo: follow the redirect, use the new URL, say so in the cell.

## Tests
None new (a doc); check.sh --no-godot must still pass.

## Checklist
- has: docs/research/opensource-candidates.md :: verified 2026-10-30
- has: docs/research/opensource-candidates.md :: last commit

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
