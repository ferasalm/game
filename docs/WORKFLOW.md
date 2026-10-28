# WORKFLOW: how the studio works (protocols, routing, limits, routes)

Why the rules in CLAUDE.md exist. Not loaded at session start. Built 2026-10-19 from reem-bot (its portable playbook,
orchestrator skill and doc check) and feras-career (its efficiency playbook), read critically, plus this repo's own
methods. Drop a rule when its why stops being true.

## Start here: one unit of work (Feras 2026-10-28: the lean process; departments are labels)
Feras -> the **father** chat (Opus high; xhigh only for planning) -> the worker from the step 3 table -> gates ->
Feras plays -> his notes become queue rows. Speed, never needless spend: each task goes to the cheapest worker that
does it well; Opus reviews every non-Opus output and owns whatever reaches Feras. tools/doc_check.py makes every queue
row name a Dept from the Routing table and a lane.
1. **Look** (free): `bash tools/status.sh`: builders, branches not on main, worktrees, the queue, Feras's list.
2. **Pick**: the top HANDOFF queue row. Its Dept is a label: the Routing table row says which skills and persona to
   load and who reviews.
3. **Who does it** (one row per worker; the first row that fits wins):

| Worker | When | Rough cost to the Claude limit | Who reviews |
|---|---|---|---|
| The father itself | a targeted read, one edit, a yes/no, a decision logged in Feras's words, a 1-3 line fix: the brief would hold the whole text | its own turns only | the gates, then itself; review-feras before Feras |
| Builder (agy, cf, oc) | anything a brief can state exactly: code, tests, renames, edits across files, docs, summaries, persona drafts (Feras 10-28: whenever the brief is shorter than the work and the risk is low or well tested; small, risky machinery: the father writes it) | ~0 (free models); Claude pays the brief and the review | tiered (Protocols: Review) |
| Haiku reader (effort high) | a read over ~20k tokens or across many files, with an exact output template | ~70k start + its reading | Opus reads only the template answer |
| review-* agent | review-code on a diff, review-player on renders, review-feras last; one each, only when the tier needs it | ~30-70k each (a fresh start) | Opus weighs the findings |
| Sonnet subagent + advisor | a scoped multi-step job where Opus is overkill and a builder can't (needs Claude tools); loop cap 3 rounds | ~67k start + its work | Opus, tiered |
| Opus child chat | long, taste, MCP (Blender, Flow, Rodin) or builder-waiting work; anything Feras may watch or answer | a new chat in its own worktree (an idle one costs nothing) | itself + review-*; the father checks status.sh |

4. **Brief**: a builder gets docs/briefs/TEMPLATE.md; a child chat or subagent gets the department brief below.
5. **The worker orchestrates** (a child chat): it routes each piece by the Routing table's lane, briefs builders and
   launches build_pipeline.sh in the background, sends reads over ~20k tokens to a Haiku high reader, reviews tiered;
   anything visual passes players-eye-gate, review-player and review-feras, then `python tools/hooks/review_stamp.py`
   (the review gate blocks sending an unstamped render). It runs check.sh and merges its checked work into main
   (standing OK). Nested agents work (10-28) but each costs a fresh start.
6. **The father** reads the report, checks it with `bash tools/status.sh` (branch on main, row updated), picks next.
   Open children are the queue rows whose Status says "child open"; status.sh lists their branches and worktrees.
7. **Evolve**: each chat upgrades one tool, check, skill or doc; every 5 chats ops-review reads /session-report
   (plugin) and review-cost; a lesson becomes a check or is archived after 30 days (D9). The claude-md-management
   plugin runs only inside /handoff and within the doc_check caps.
Emergency mode (emergency-efficiency skill, the 5-hour window past 50%) suspends child chats: one director chat,
builders and Haiku readers only, until the window resets.

**Department brief** (fill every line; a child chat gets it as its first message, a subagent as its prompt):
```
Department: <Id> (a label: Routing table). Queue row: <#>. Model: Opus <effort> | Sonnet + advisor.
Skills: <names; a skill the chat does not list yet: Read .claude/skills/<name>/SKILL.md>. Persona: <.agents/skills name>
Goal: <one line; player-visible where it can be>
Context: <the decisions, files and CANON lines it needs; no chat history>
Lane plan: <pieces for agy / cf / oc, Haiku readers, reviewers; what the chat does itself>
May edit: <paths>. Do NOT edit: <paths other chats own right now>. Commit and merge: <yes | no, the father does>
Done when: <check.sh passes; the gate or render; merged to main; queue row updated>
Report: 15 lines or fewer: what changed (commits), runs launched, what failed, questions for Feras.
```

## The budget
Feras is on Claude Pro ($20/month): a 5-hour usage window plus a weekly cap, shared with his other projects. Money is
fixed; throughput is the limit. Every turn re-sends the whole chat (cheap when cached, still counted), so the costs
are: what loads at start, how long a chat runs, what gets read, and output.

## Protocols
- **Start:** the hook prints the sync for this worktree; then the HANDOFF line; then get_usage.
- **Brief:** docs/briefs/TEMPLATE.md (<= 80 lines, with a Do NOT edit list).
- **Build:** slots (tools/slots.sh), then the pipeline (tools/build_pipeline.sh).
- **Review (tiered, Feras 10-28: Opus never reads needlessly, and signs off on whatever reaches Feras):**
  1. Gates first: check.sh, build_gate (.result first line). FAIL, NOWORK or BREACH goes back unread.
  2. Big diffs (over ~300 lines or ~10 files): a Haiku high pass (or a free lens, Readers) lists the misses against
     the brief's Checklist; small diffs skip to 3.
  3. Opus reads that list, the WARN lines and the risky hunks only: logic/, saves, hooks, settings.json, anything no
     test reaches; review-code on the whole diff only when the tier-2 list is not clean.
  4. Anything that reaches Feras: the eye gate (tools/eye_gate.sh), review-player + review-feras, then
     `python tools/hooks/review_stamp.py <file>`; the review_gate hook blocks SendUserFile and Artifact on an
     unstamped render (tools/hooks/review_gate.py).
- **Handoff:** at a unit boundary past ~250k context (review-heavy ~300k) or ~85% of the 5-hour window (CLAUDE.md). It records one improvement made and one proposed.
- **ops-review:** every 5 sessions, or at 50% of the window: usage trend and start cost; promote lessons to checks;
  condense the notes on schedule; dispatch research from the department queues and read the digests (Research
  protocol); archive idle sessions.
- **Lesson lifecycle:** a lesson is added, then promoted to a test, tool, hook or skill line, or archived after 30 days
  unused. A rule the agent keeps breaking becomes a check.

## Routing (one table; departments are labels, Feras 10-28 option B)
A department is a label, not an agent: the HANDOFF queue's Dept column names a Dept below, and that row says which
skills and persona the worker loads, its lane and its reviewer. Every brief names its persona; our rules (CLAUDE.md,
.claude/rules/code.md, CANON) outrank persona text. Lanes: agy = Godot code with tests and UI renders, and Python
tools, docs and reviews whenever its quota is free (row 12); cf = Godot code when agy is full, Python tools; oc = text, drafts, review lenses (<= 2 Godot runs, 1 text run: Limits); chat =
Opus for plan, taste, MCP, review. No department chat stays open between tasks; its lessons and research queue live in
its skill folder. tools/doc_check.py fails on an unknown Dept, a persona with no .agents/skills/<name>/SKILL.md, a
reviewer with no .claude/agents/<name>.md, and any .claude/agents/dept-*.md (retired to ~/.claude/archive, D7).

| Request | Dept | Skills | Persona | Lane | Reviewer |
|---|---|---|---|---|---|
| the queue, picks, briefs, reading reports (Feras directs) | Producer | builders; tools/status.sh | - | chat (plan) | review-feras |
| process, tools, hooks, checks, merging PASS runs | Ops | builders, ops-review; emergency-efficiency when the window is tight | - | builder (agy, cf) + chat (review) | review-code + review-cost |
| combat and systems design: specs, balance | Gameplay | builders + a spec in docs/design/ | game-designer | chat (plan) | review-feras |
| Godot gameplay code and tests | Gameplay | builders | godot-gameplay-scripter | builder (agy, cf) | review-code |
| levels, encounters, the roof layout | Gameplay | builders; docs/design/systems-map.md | level-designer | builder (agy) + chat (review) | review-code + review-player |
| shaders, VFX, rain, neon light | Art | builders; docs/design/art-bible.md | godot-shader-developer | builder (agy) | review-code + review-player |
| images, 3D models, sprites, renders | Art | flow-media, 3d-model, sprite-bake; docs/design/art-bible.md | technical-artist, blender-addon-engineer | chat (MCP) | review-player |
| sound and music (CC0 first) | Art | builders; docs/design/art-bible.md | game-audio-engineer | builder (agy) + chat (taste) | review-player |
| story, dialogue, names | Narrative | docs/CANON.md + the story bible | narrative-designer | builder (oc) drafts + chat (taste) | review-canon |
| menus, HUD, UI text | UI | .agents/skills/ui-card; docs/design/ui.md, rpg-menus.md | ui-designer | builder (agy) + chat (taste) | ui-finish-gate-reviewer + review-player |
| the player's eye before Feras plays; his play sessions | QA | players-eye-gate + the F12 capture (features/debug/playtest) | - | chat (review) | review-player + review-feras |
| audience, price, store page, playtests (drafts only) | Market | market-player; role cards (Business Strategist, Product Manager, UX Researcher, Persona Walkthrough Specialist, Feedback Synthesizer) | - | builder (oc) drafts + chat (review) | review-market |

## Limits (one table)
| Limit | Value | Enforced by |
|---|---|---|
| Godot builder runs, machine-wide | 2 at once (CAP_GODOT=2; agy CAP_AGY=2, Cloudflare DeepSeek CAP_CF=2; a RUN_KIND=py run counts toward its builder cap only) | tools/slots.sh (refuses when full) |
| Text run (opencode, OpenRouter :free; no Godot) | 1 (CAP_OC=1) | tools/slots.sh |
| Godot test suites at once | 2 (CHECK_SLOTS=2) | tools/check_slot.sh |
| Free memory before a Godot run | >= 3000 MB (MIN_FREE_MB=3000) | tools/slots.sh |
| Builder with no commit | killed after 25 min (IDLE_MIN=25); result NOWORK | tools/build_pipeline.sh |
| OpenRouter :free requests | 50 a day, shared by all :free models | the provider; check before a run |
| Claude's handoff | a unit boundary past ~250k context (review-heavy ~300k) or ~85% of the 5-hour window | tools/hooks/token_handoff.py; review-cost |
| Always-loaded notes | 27 KB each; lines: CLAUDE.md 80, HANDOFF 60, DECISIONS 70, LESSONS 100 (warns at 75%) | tools/doc_check.py |
| Godot code | <= 200 lines a file, <= 40 lines a function | tools/lint_gd.py |
| Paid image APIs | <= $1 each, only with Feras's OK | tools/pre_spend.py (see Routes) |

## Routes (free first)
| Need | Free route first | Paid fallback and cap |
|---|---|---|
| Images | Flow, Nano Banana (Feras's Flow outputs; flow-media skill) | Paid image APIs (Runware, OpenRouter image) only after Flow fails for the job, <= $1, only on Feras's OK (feras-notes: paid was once used before free) |
| Video | Flow, Omni (title loop, VFX plates; flow-media skill) | Paid video only on Feras's OK, cost named first |
| 3D models | Blender MCP search_assets / import_asset (CC0: Poly Haven, Poly Pizza; Sketchfab only with a licence check); open-source image-to-3D on a free host (TRELLIS, Hunyuan3D, TripoSR; unverified) | Hyper3D Rodin while its credits last: name the cost first, log in SPEND.md, one approved hero asset before any batch |
| Sprites | tools/art bake: offline renders (bake_sprites.tscn); no 3D at runtime | none needed |
| Sound and fonts | CC0 SFX (Freesound CC0, Kenney); CC0 textures and fonts (OFL) | none; Feras's OK before each download, plus a manifest entry |
| Research | see Research protocol | Cloudflare DeepSeek, up to $10 over its free neurons (Feras, 2026-10-23) |

The PreToolUse hook tools/pre_spend.py blocks paid generation tools unless one of Feras's last 8 messages says "spend ok"
(wired in .claude/settings.json PreToolUse, P3.9; Hyper3D calls get a credit-cost reminder). Before Rodin access ends, prove the free 3D route on one character.

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
- **The reading rule** (one rule, CLAUDE.md): Claude reads small targeted excerpts itself (grep, then the lines it
  needs); a Haiku high reader only for a read over ~20k tokens or across many files.
- **Claude's delegated reading:** Haiku at effort high (calibrated 2026-10-27: docs/research/calibration-2026-10.md).
  Max adds ~55% tokens for no gain; low gave one false verdict.
- **Review lenses:** nemotron-3-ultra :free (6/6 on the planted set, 0 decoy flags), or Haiku low when the free route
  is not available. Free route: tools/oc_review.sh, or the OpenRouter send-message tool with public content only.

## Model routing on Pro
| Work | Who | Effort |
|---|---|---|
| Design, specs, briefs, hard engineering, judging art and renders | Opus | high |
| Anything briefed exactly: code, content, tests, docs, audits | agy (Gemini 3.8 Flash), Cloudflare DeepSeek, or opencode :free for text | the tool's default |
| Reviewing and merging builders' branches, small fixes | the chat that launched the run (the father or its child), tiered (Protocols: Review) | high |
| Scoped multi-step Claude work where Opus is overkill | a Sonnet subagent (Agent tool, model sonnet) with the advisor; loop cap 3 rounds | default |

Speed, never needless spend: the cheapest worker that does the task well (Start here, step 3). Sonnet and the advisor
(tested 2026-10-28): an Agent-tool subagent on Sonnet has the `advisor` tool and can call it (one probe, ~67k start
tokens), so "Sonnet with the Opus advisor" is a subagent, not a child chat; a Sonnet or Haiku chat Feras opens gets
`/advisor opus`. Claude subagents only where a builder can't, at most 2 at once per chat.

## Builder loop (agy, Cloudflare DeepSeek, opencode)
Low on Claude limit: .claude/skills/emergency-efficiency/SKILL.md overrides this section. Models and caps: tools/builders.conf.
Lanes: agy for Godot code with tests and UI renders, and Python tools, docs and reviews; Cloudflare DeepSeek when agy is
full; opencode :free for text. A Python or docs-only run sets RUN_KIND=py: its builder's slot but no Godot slot or memory
floor, `check.sh --no-godot`, the gate fails it on any Godot file, merge_run reruns the full check. Every
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
   other merge runs check.sh. It removes the worktree and branch. The child chat that started a run merges
   it; a father that launched a run reviews (tiered) and merges it on PASS. A repeated miss
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
| A lane and a department on every queue row (doc_check); one model and effort per chat; one task per chat, hand off past ~250k context | Adopted | Effort can't change mid-chat; switching models drops the cache; Pro windows are small |
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
6. **Spec first.** An Opus chat writes docs/design/<feature>.md (<= 60 lines, with acceptance tests); a builder builds from it.
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
