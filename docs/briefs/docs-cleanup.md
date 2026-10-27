# Brief: docs-cleanup (<= 60 lines; design docs only, no code)
You are in your own worktree on branch oc/docs-cleanup (made from claude/puzzles-streamline-f7ef2d). Follow
GEMINI.md and AGENTS.md. You may give one doc to the narrative-designer subagent; you check and commit its edits.

## Why
A design audit (2026-10-23) found rules the owner superseded in docs/DECISIONS.md that still live on in design docs.
Builders read those docs and build the old rule. Make each doc agree with DECISIONS, changing as little as possible.

## Read first
docs/DECISIONS.md (the binding rules; newest wins). Then only the lines named below (grep, do not read whole files).

## What to build (edit only these spots; keep the doc's voice, plain English, short lines <= 120 chars)
1. docs/design/combat.md (top, lines 1-3) and docs/design/zayd-moves.md (lines 3-4): add one line under the title:
   "Demo combat stays these timeline battles; action combat (DECISIONS 2026-10-23) replaces them after the demo."
2. docs/archive/design-3d/prototype.md (near line 24, "refill after each"): HP and SP carry over between fights; the sabil
   refills them (DECISIONS 2026-10-21 save spot).
3. Arabic script: DECISIONS 2026-10-22 says world text is Musnad only and there is no Arabic script in the game
   (HUD/UI English; menu headings and the logo carry Musnad where Arabic was). Fix: docs/design/ui.md (lines 8, 28,
   106, 128, 152: "Arabic" title pairs -> Musnad pairs; title_pair(en, ar) -> title_pair(en, musnad)),
   docs/design/world.md line 5 ("neon in Arabic script" -> "neon in Musnad letters"), docs/design/night-sanaa.md
   line 46, docs/design/v03-text.md lines 95-102, docs/archive/design-3d/v03-plan.md line 124. Never write Arabic letters.
4. Camera: DECISIONS 2026-10-23 = close follow outdoors, automatic, a three-quarter side angle of about 32 deg;
   when a wall blocks the view the camera rises toward isometric. Fix docs/design/art-bible.md line 69 (~26 deg) and
   docs/design/night-sanaa.md line 22 (35 deg) to that rule (one short sentence each, cite DECISIONS 2026-10-23).
5. docs/archive/design-3d/demo-plan.md line 7: replace the old rooftop-v3 places (workshop alcove, corridor, vista, bridge,
   east roof) with "the five roofs R1-R5 of level-1.md (Abu Nabil on R2, the valve puzzles on R5)".
6. docs/design/music.md line 1: no menu or merchant tracks; menus and Abu Nabil's stall keep the area music
   (explore_souq) (DECISIONS 2026-10-22 music).
7. docs/archive/design-3d/playtest-2026-10-23.md items 5, 8 and 9: append " (superseded: five-roof level-1.md, DECISIONS
   2026-10-23)" to each item's first line.
8. If a named line number is off, grep for the phrase; if a spot no longer holds the old rule, leave it and say so.

## Do NOT edit
`docs/DECISIONS.md`
`docs/decisions-archive.md`
`HANDOFF.md`
`CLAUDE.md`
`docs/LESSONS.md`
`docs/briefs/`
`docs/design/level-1.md`
`docs/design/valve-puzzles.md`
`docs/design/slice.md`
`features/`
`core/`
`content/`
`tools/`
`localization/`

## Tests
None new (docs only). `python tools/doc_check.py` must pass; `bash tools/check.sh` must end "all checks passed".

## Proof
`bash tools/check.sh` raw last 15 lines; one commit per numbered item is fine; final message lists each item as
done or skipped (why) and ends with `Built-by: deepseek-v4.1-flash (opencode, Cloudflare)`.
