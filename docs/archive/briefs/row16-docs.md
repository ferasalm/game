# Brief: row16-docs (HANDOFF row 16, Ops; three docs, no code)
You are in your own worktree on branch gemini/row16-docs (made from origin/main). Follow GEMINI.md, including
<review_misses>. Load the minimal-change-engineer skill (our rules outrank its text).
Timebox: 45 min. First commit within 15 min, then small WIP commits: no commit for 25 min (IDLE_MIN) = NOWORK.

## Why
Feras (10-29): "process first, M1 Sat": one page that shows how we work, model cards so Claude picks the right free
model, and open-source candidates for code, tools and sound. Pillar served (docs/VISION.md): a small game finished
fast, combat feel wins ties (cheaper process = more budget for combat).

## Read first
docs/WORKFLOW.md (Start here, Routing, Protocols), docs/audits/2026-10-29-process-review.md sections 2, 3, 5, 6,
HANDOFF.md (Queue, This week), tools/builders.conf (model ids), docs/research/calibration-2026-10.md,
docs/design/art-bible.md (section headings only), docs/VISION.md, and the PDF
C:/dev/game/inbox/docs/ideas opensource game.pdf (a Gemini chat: ideas only, never facts).

## What to build
1. docs/HOW_WE_WORK.md (<= 120 lines): a title, one line saying it is updated whenever docs/WORKFLOW.md Protocols
   change; a fenced mermaid flowchart (flowchart LR) of the loop: Feras -> Opus chat -> brief -> builder pipeline
   (agy/cf/oc) -> build gate -> cross-review (other model family) -> Opus gate -> eye gate -> main -> handoff ->
   calendar + feras/BRIEFING.md -> Feras plays -> notes back to the queue; a roles table (Feras, Opus chat, builders,
   Haiku and review-* agents: decides / does / reports, from audit section 6); the cost rules (audit section 3, at
   most 8 bullets); the week (copy HANDOFF This week as it stands). Plain words, short lines; no new rules.
2. .claude/skills/builders/models.md (<= 80 lines): one card per model: agy Gemini 3.8 Flash, DeepSeek V4.1 Flash
   (cf and opencode), nvidia nemotron 3 ultra :free (OpenRouter), GLM-5.3-Flash (Cloudflare), and up to 3 other
   OpenRouter :free models you find. Each card: id as in tools/builders.conf if listed; Artificial Analysis
   intelligence and coding index and the page date you read, every number marked "(unverified, AA <date>)"; our
   calibration scores only from docs/research/calibration-2026-10.md and audit section 5 (copy, never invent; "none
   yet" when absent); known failure modes from those docs; best use (build, review lens, text). End with the rule:
   a new model is used only after a calibration run (D11).
3. docs/research/opensource-candidates.md (<= 80 lines): a table of up to 15 open-source repos or assets for code,
   tools and sound first, art only if it fits docs/design/art-bible.md: name | URL | licence (read from the repo's
   LICENSE file) | what it gives Neon Glitch | fit (code/tool/sound/art) | manifest source line. Licence rule: CC0,
   MIT, BSD, Apache first; CC-BY only with an attribution line; never GPL code, never NC (the game goes premium).
   Top line: "Unverified research (D18): ideas, not facts; Claude verifies a licence before any import."

## Do NOT edit
`CLAUDE.md`
`HANDOFF.md`
`docs/DECISIONS.md`
`docs/LESSONS.md`
`docs/WORKFLOW.md`
`.claude/skills/builders/SKILL.md`
`inbox/`

## May edit
none

## Ripple
docs/MAP.md lists new files: run python tools/map.py after git add. Nothing else reads these three files yet; Opus
adds the pointers (HANDOFF, builders skill, WORKFLOW) after review.

## Pre-mortem
- Invented benchmark numbers or licences: every number carries its source and date; licences read from LICENSE files.
- A GPL or NC entry slips in: the licence rule above; Opus checks each row.
- The diagram drifts from WORKFLOW: copy step names from WORKFLOW and the audit only.

## Tests
none: docs-only run; check.sh --no-godot (doc_check, MAP) and Opus's review prove it.

## Checklist
- file: docs/HOW_WE_WORK.md
- file: .claude/skills/builders/models.md
- file: docs/research/opensource-candidates.md

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
