# WORKFLOW: how the studio works (protocols, departments, limits, routes)

Why the rules in CLAUDE.md exist. Not loaded at session start. Built 2026-10-19 from reem-bot (its portable playbook,
orchestrator skill and doc check) and feras-career (its efficiency playbook), read critically, plus this repo's own
methods. Drop a rule when its why stops being true.

## The budget
Feras is on Claude Pro ($20/month): a 5-hour usage window plus a weekly cap, shared with his other projects. Money is
fixed; throughput is the limit. Every turn re-sends the whole chat (cheap when cached, still counted), so the costs
are: what loads at start, how long a chat runs, what gets read, and output.

## Protocols
- **Start:** the hook prints the sync for this worktree; then the HANDOFF line; then get_usage.
- **Brief:** docs/briefs/TEMPLATE.md (<= 60 lines, with a Do NOT edit list).
- **Build:** slots (tools/slots.sh), then the pipeline (tools/build_pipeline.sh).
- **Review:** a panel of 2 lenses for small runs, 4 for anything that reaches Feras; then the eye gate (tools/eye_gate.sh) before he plays.
- **Handoff:** at ~100k work tokens (get_usage Messages). It records one improvement made and one proposed.
- **ops-review:** every 5 sessions, or at 50% of the window: usage trend and start cost; promote lessons to checks;
  condense the notes on schedule; dispatch research from the department queues and read the digests (Research
  protocol); archive idle sessions.
- **Lesson lifecycle:** a lesson is added, then promoted to a test, tool, hook or skill line, or archived after 30 days
  unused. A rule the agent keeps breaking becomes a check.

## Departments
Each department is one skill plus one reviewer agent, not an always-on chat (that would pay ~89k start tokens every
turn). Its lessons live in its skill folder (lessons.md), read only when it works.

| Department | Skill(s) | Reviewer |
|---|---|---|
| Producer (the orchestrator chat; Feras directs) | builders | n/a |
| Ops and efficiency | ops-review | review-cost |
| Art and assets | flow-media, 3d-model, sprite-bake; art bible | review-player |
| Gameplay (design and code) | builders + spec; game-designer, level-designer, godot-gameplay-scripter personas | review-code |
| Narrative | narrative-designer persona + bible | review-canon |
| UI and menus | ui role card; docs/design/ui.md; rpg-menus.md | review-player (UI half) |
| QA, the player's eye | players-eye-gate + F12 capture | review-player |
| Market and player | market-player skill; role cards (Business Strategist, Product Manager, UX Researcher, Behavioral Nudge Engine, Persona Walkthrough Specialist, Feedback Synthesizer) | review-market |

## Limits (one table)
| Limit | Value | Enforced by |
|---|---|---|
| Godot builder runs, machine-wide | 2 at once (CAP_GODOT=2; agy CAP_AGY=2, Cloudflare DeepSeek CAP_CF=2) | tools/slots.sh (refuses when full) |
| Text run (opencode, OpenRouter :free; no Godot) | 1 (CAP_OC=1) | tools/slots.sh |
| Godot test suites at once | 2 (CHECK_SLOTS=2) | tools/check_slot.sh |
| Free memory before a Godot run | >= 3000 MB (MIN_FREE_MB=3000) | tools/slots.sh |
| Builder with no commit | killed after 25 min (IDLE_MIN=25); result NOWORK | tools/build_pipeline.sh |
| OpenRouter :free requests | 50 a day, shared by all :free models | the provider; check before a run |
| Claude's handoff | ~100k work tokens (get_usage Messages) | Handoff protocol; review-cost |
| Always-loaded notes | 27 KB each; lines: CLAUDE.md 80, HANDOFF 60, DECISIONS 70, LESSONS 100 (warns at 75%) | tools/doc_check.py |
| Godot code | <= 200 lines a file, <= 40 lines a function | tools/lint_gd.py |
| Paid image APIs | <= $1 each, only with Feras's OK | tools/pre_spend.py (see Routes) |

## Routes (free first)
| Need | Free route first | Paid fallback and cap |
|---|---|---|
| Images | Flow, Nano Banana (Feras's Flow outputs; flow-media skill) | Paid image APIs, <= $1 a job, only on Feras's OK |
| Video | Flow, Omni (title loop, VFX plates; flow-media skill) | Paid video only on Feras's OK, cost named first |
| 3D models | Blender MCP search_assets / import_asset (CC0: Poly Haven, Poly Pizza; Sketchfab only with a licence check); open-source image-to-3D on a free host (TRELLIS, Hunyuan3D, TripoSR; unverified) | Hyper3D Rodin while its credits last: name the cost first, log in SPEND.md, one approved hero asset before any batch |
| Sprites | tools/art bake: offline renders (bake_sprites.tscn); no 3D at runtime | none needed |
| Sound and fonts | CC0 SFX (Freesound CC0, Kenney); CC0 textures and fonts (OFL) | none; Feras's OK before each download, plus a manifest entry |
| Research | see Research protocol | Cloudflare DeepSeek, up to $10 over its free neurons (Feras, 2026-10-23) |

The PreToolUse hook tools/pre_spend.py blocks paid generation tools unless one of Feras's last 8 messages says "spend ok"
(settings.json wiring pending, P3.9). Before Rodin access ends, prove the free 3D route on one character.

## Research protocol (audit plan D18)
Everyone except Claude researches. Claude writes the questions and reads only the digests.
- Each department keeps research-queue.md (open questions) and an upgrade log in its skill folder.
- When a queue holds 3 or more questions, or at ops-review, Claude writes one prompt per question: a big question
  goes to a Gemini Deep Research prompt (Argon High) that Feras runs and shares as a doc; a small lookup goes to
  opencode + OpenRouter :free with web fetch, or agy; a code or tool question goes to Cloudflare DeepSeek.
- Results go to docs/research/<department>/<date>-<topic>.md, marked unverified: ideas, never facts.
- The calibrated reader (Readers below) digests each into <= 30 lines: adopt / adapt / skip, with sources. Claude reads
  only the digest, then updates the department card, its lessons and its tools.
- One department gets a deep upgrade at each ops-review, in rotation.

## Readers
- **Claude's own reading tasks:** Haiku at effort high (calibrated 2026-10-27: docs/research/calibration-2026-10.md).
  Max adds ~55% tokens for no gain; low gave one false verdict.
- **Review lenses:** nemotron-3-ultra :free (6/6 on the planted set, 0 decoy flags), or Haiku low when the free route
  is not available. Free route: tools/oc_review.sh, or the OpenRouter send-message tool with public content only.

## Model routing on Pro
| Work | Who | Effort |
|---|---|---|
| Design, specs, briefs, hard engineering, judging art and renders | Opus | high |
| Anything briefed exactly: code, content, tests, docs, audits | agy (Gemini 3.8 Flash), Cloudflare DeepSeek, or opencode :free for text | the tool's default |
| Reviewing and merging branches, small fixes | Sonnet (or Opus when the chat is Opus anyway) | medium |

Claude's own tasks go to Haiku first, Sonnet only when Haiku can't do it well (Readers). Claude subagents only where a
builder can't (art judgment loops, Opus code review), at most 2 at once.

## Builder loop (agy, Cloudflare DeepSeek, opencode)
Low on Claude limit: .claude/skills/emergency-efficiency/SKILL.md overrides this section. Models and caps: tools/builders.conf.
Lanes: agy for Godot code with tests and UI renders; Cloudflare DeepSeek when agy is full; opencode :free for text. Every
brief names one game-dev skill (.agents/skills/). Free models may train on prompts: only public repo content goes in a brief.

1. **Brief** from docs/briefs/TEMPLATE.md, with a Do NOT edit list so parallel runs never share files.
2. **Build**, from the main checkout, in the background: `bash <session worktree>/tools/build_pipeline.sh <oc|agy> <task>
   <brief> <base>`. It builds, runs check.sh, one free fix pass, check, then tools/build_gate.py, which writes
   ../game-wt/<task>.result.
3. **Read** the .result's first line only: NOWORK (nothing real built), BREACH (touched a Do NOT edit path) or FAIL means
   rerun or fix the brief, and read nothing else. PASS: read its WARN lines; run `bash tools/agy_review.sh <task>` only for
   what a WARN names, and the renders. Then a Haiku subagent (effort high) compares the diff with the brief and its
   Checklist and lists the misses; Opus reads only that list, the WARN lines and the renders.
4. **Merge:** `bash tools/merge_run.sh <task> <gemini|oc>`. A fast-forward onto the checked commit reuses the check; any
   other merge runs check.sh. It removes the worktree and branch. Review-and-merge chats run on Sonnet. A repeated miss
   goes into GEMINI.md <review_misses>.
5. **Runs belong to the chat that started them.** A chat that ends early leaves its runs going only while its session
   stays open. The next chat checks `git -C ../game-wt/<task> log` and the log; a dead run is restarted with the same
   command (the worktree and its commits are kept).
6. **Cloudflare DeepSeek** (Workers Paid; model in tools/builders.conf): `bash tools/cf_build.sh <task> <brief> <base>`.
   Note its spend (Cloudflare dashboard, AI, Workers AI) in HANDOFF after each run.

## Practices taken from reem-bot and feras-career
| Practice | Here | Why |
|---|---|---|
| Notes split by change rate: CLAUDE.md rare, HANDOFF rewritten, DECISIONS = rules in force, LESSONS curated; full log in decisions-log.md | Adopted | Old state never reads as current |
| @ imports of HANDOFF, DECISIONS, LESSONS under the 27 KB cap | Adopted, enforced by doc_check | reem-bot's loaded log grew past 100 KB: paid at every start |
| /handoff at the end of every session | Adopted (handoff skill) | The next chat starts with no resume step |
| Model and effort on every next step; one model and effort per chat; one task per chat, hand off past ~100k work tokens | Adopted | Effort can't change mid-chat; switching models drops the cache; Pro windows are small |
| SessionStart hook with a sync report | Adopted | Catches a stale branch before work starts |
| Grep first, read only the needed lines; never read generated files | Adopted, enforced by deny rules in .claude/settings.json | A rule nobody enforces drifts |
| A check counts only when its output was read; every bug gets a regression test | Adopted (tools/check.sh, run_godot.sh) | A summary line hid broken results before; fixes stay fixed |
| No subagents to explore; delegate only token-heavy mechanical work | Adopted; Claude's own tasks go to Haiku (Readers) | Measured: 150-290k tokens per worker |
| Questions batched, each with a recommended default; paste-ready prompt in HANDOFF | Adopted | One round trip instead of several |
| Hand-written MAP.md | Replaced: generated by tools/map.py | Hand upkeep every session |
| Orchestrator skill with Haiku workers | Superseded by the builders skill (Builder loop) | A written spec and a builder beat a brief plus worker plus review on Pro |

## This repo's own methods
1. **Pure logic + headless tests.** Rules are checked by a test summary line, not by playing or screenshots.
2. **Summaries, not logs.** tools/check.sh prints one line per step; full logs stay in `.check/` to grep on failure.
3. **Levels as text.** A 20-line ASCII map plus JSON builds the scene; nobody edits a big .tscn by hand.
4. **Content as JSON with validation.** Balance changes are one-line diffs Feras can tune himself.
5. **Generated code map.** One purpose line per file feeds docs/MAP.md; the check fails when it is stale.
6. **Spec first.** An Opus chat writes docs/design/<feature>.md (<= 60 lines, with acceptance tests); a Sonnet chat builds from it.
7. **Small pictures, only when judging visuals:** 640x360 screenshots (~300 tokens); regressions by pixel diff.
8. **Placeholders first.** Art never blocks code; Claude never opens art files to write code.
9. **Pinned engine, strict parser.** Godot 4.7.2; Godot 3 habits and typos fail at import, before a debug loop starts.
10. **Asset and licence manifest from day one.** No costly audit before a release.
11. **CI builds the game.** Feras downloads a Windows build to play; no tokens spent on how to run it.
12. **Usage ledger** (docs/USAGE.md): one row per session with its share of the 5-hour window.

## How Feras can save tokens (prompt tips)
- Put the whole job in the first message, with what you already know; each missing detail costs a round trip.
- Answer numbered questions by number ("1 yes. 2 skip. 3 use your default").
- Say "use your defaults and log them" when you don't mind; Claude then stops only for real blockers.
- Name the output and its size ("just the screenshot verdict", "max 10 lines"); say what better means, not "improve it".
- Disagree once with "log decision: ..." so it is never argued again.
- `/clear` or a new chat between tasks; `/usage` shows what is left of the window; `/rewind` undoes a wrong turn.
