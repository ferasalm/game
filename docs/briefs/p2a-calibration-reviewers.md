# Brief P2a: calibration, reviewer agents, builders skill (Sonnet main, Opus advisor)
Written by Opus 5.5, 2026-10-27, for package P2 of docs/audits/2026-10-27-process-audit-plan.md (split into
P2a + P2b). This brief is the whole job. Do not read the plan beyond what a step names.

## Rules for this chat
- Feras types `/advisor opus` first. Ask the advisor before any design choice that this brief leaves open, and
  whenever a step fails twice. Never loop: at most 3 fix rounds per step. Then mark the checklist line open with
  the reason, and go on.
- Grep, then read only the named lines. No full reads of docs/ files over 100 lines. Hand reading-heavy or
  mechanical work to Haiku subagents with the exact briefs below.
- Report only at milestones: calibration done, agents done, merged. Hand off at ~100k work tokens (get_usage
  Messages): commit WIP, then write the next prompt into HANDOFF Efficiency.
- Work in your worktree. Never run git in C:\dev\game. Merge to main only with `bash tools/check.sh` green and its
  FAIL lines read.

## Step 1: calibration (checklist P2.0). Which reader and lens model is cheapest without losing quality
Setup:
- `git worktree add ../cal-1981e15 1981e15`. This is the code before P1, so the answers below are true there.
- Remove the worktree at the end.

Gold set A (reading). The brief for every candidate, verbatim:
> Read only these files in <worktree>: tools/slots.sh, tools/build_pipeline.sh, tools/build_gate.py, tools/map.py,
> tools/check.sh. For each claim, answer CONFIRMED or FALSE, with the file:line and a quote of 12 words or fewer.
> Output exactly 12 lines: `<id> | CONFIRMED/FALSE | file:line | quote`. If you are not sure, write UNSURE. Never guess.
> A1 slots.sh caps are 2 agy / 3 cf / 0 oc. A2 nothing reads free memory before a launch. A3 build_pipeline.sh
> exits 0 whatever the verdict. A4 build_pipeline.sh never checks that the local base equals origin/<base>.
> A5 no watchdog kills an idle builder. A6 map.py lists untracked files. A7 a git pre-commit hook runs check.sh.
> A8 build_gate.py reads only added (+) diff lines. A9 slots.sh run from .claude/worktrees/x looks for runs in
> .claude/worktrees/game-wt. A10 check.sh chains its Python tool tests with &&. A11 check.sh runs the Godot suite
> with no timeout. A12 build_gate.py exits 0 on BREACH.

Answer key:
| Claim | Answer | Where |
|---|---|---|
| A1 | CONFIRMED | slots.sh:2 |
| A2 | CONFIRMED | |
| A3 | CONFIRMED | build_pipeline.sh:64 `cat "$res"` |
| A4 | CONFIRMED | |
| A5 | CONFIRMED | |
| A6 | CONFIRMED | map.py:48 |
| A7 | FALSE | there are no hooks |
| A8 | CONFIRMED | build_gate.py:110-117 |
| A9 | CONFIRMED | slots.sh:9-17 |
| A10 | CONFIRMED | check.sh:17 |
| A11 | FALSE | GODOT_TIMEOUT=600, check.sh:19 |
| A12 | FALSE | it exits 1, build_gate.py:142-143 |

Gold set B (review lens):
- On a throwaway branch `cal/planted` (never pushed or merged; delete it after), make one commit on a small logic
  file and its test, both of your choice.
- The commit plants exactly 6 defects:
  - B1: a test asserts a hard-coded value where the code's result was compared;
  - B2: one `assert`/`check(` line removed from a test;
  - B3: a gameplay number written into code instead of content JSON;
  - B4: `get_node("../X")`, a lookup by path;
  - B5: `if OS.has_feature("headless"): return true`, a test-detection branch;
  - B6: assets/manifest.json, one entry's "licence" changed.
- The commit also makes 2 harmless changes, which serve as decoys: a comment typo fix and a local variable rename.
- The lens brief, verbatim:
  > You review a builder's diff. Flag only correctness bugs, gaming of tests, and breaks of these rules: no gameplay
  > numbers in code; no node lookups by path; tests and assets are not to be edited unless allowed. Output at most
  > 12 lines: `severity | file:line | issue | evidence`. No style notes.
- Score: the number of planted defects flagged out of 6, and false critical flags on the decoys.

Candidates (run them in this order; each gets the same brief, word for word):
1. Haiku with effort low, high and max. Use the Agent tool, subagent_type Explore, model haiku, with
   effort set. One run each for A and for B.
2. Two OpenRouter `:free` models. Pick them with `mcp__openrouter__list-models`: the two largest-context `:free`
   models with good coding rank. Never a paid slug.
   - B: one request each through `mcp__openrouter__send-message`, with the diff pasted.
   - A: one request each with the 5 files pasted. Concatenate them with a script and send the file content, not
     your own typing.
   - Budget: at most 10 requests in total (the shared free quota is 50 a day).

Record per run: score, false claims, subagent tokens (from the Agent result), and the window % before and after
(get_usage).

The bar for each role:
- reader (A): score >= 90% of Haiku max's, and 0 wrong verdicts on A7, A11, A12;
- lens (B): >= 5 of 6, and 0 false critical flags.
The cheapest passing candidate wins each role. Order from cheapest: free, Haiku low, Haiku high, Haiku max, Sonnet.

Write docs/research/calibration-2026-10.md (<= 40 lines): the table, the winners, and the date to recheck (the
first ops-review).

## Step 2: reviewer agents (P2.7)
- Six files: `.claude/agents/review-{code,player,canon,cost,market,feras}.md`.
- Frontmatter:
  - `name`, `description` (one line: when to use it);
  - `model`: the lens winner from Step 1; if that is a free model, haiku here, and the routing table names the free
    route;
  - `tools: Read, Grep, Glob`, `maxTurns: 8`, `effort` from Step 1;
  - `omitClaudeMd: true` only if `claude --version` >= 2.1.271.
- Each body is at most 40 lines. It states: its inputs (exact files), what to flag (correctness and stated
  requirements only), and the output contract (<= 15 lines: `severity | file:line | issue | evidence`). Lenses:
  - **code**: correctness, the B1-B5 reward-hack patterns, untested branches, Ripple misses.
  - **player**: renders/frames against docs/design/acceptance.md (P2b writes it; until then the retro's B table).
    Legibility, colour, motion, light, cropped portraits.
  - **canon**: VISION, DECISIONS and docs/story/bible.md. Names, places, tone, drift from the pillars.
  - **cost**: the session's tool calls and reads against the brief; what to cut next time.
  - **market**: the hook, the first 30 s, readability for a new player, the comparable bar.
  - **feras**: fresh eyes. Inputs: the output, plus docs/feras-notes.md, DECISIONS and VISION. It asks "what would
    Feras notice or object to?" It flags any repeat of a feras-notes entry.
- Seed docs/feras-notes.md (<= 40 lines) with Haiku H1 below.
- Verify: run review-code and review-feras on cal/planted. review-code must flag >= 5/6. Then check that every agent
  file loads: in a fresh chat it shows in the agent list with its description.

Haiku H1 brief (Explore, haiku, effort from Step 1, verbatim):
> Read C:\dev\game\.claude\worktrees\<yours>\docs\audits\2026-10-26-overnight-retro.md (section B) and every
> C:\dev\game\inbox\playtest\2026-10-27_*\state.json ("note" field only). Write nothing. Output at most 40 lines,
> one per distinct problem Feras raised: `<short name> | what he saw | the check that would have caught it
> (render / test / review)`. Merge duplicates. Add these five he repeated in chat: dialogue and menu portraits
> cropped; light drawn as an isolated rectangle; black-and-white sprites; paid Runware used before free Flow;
> unbalanced combat. No other commentary.

## Step 3: builders skill (P2.1, P2.8) and the prompt recipes Feras asked for
- `.claude/skills/builders/SKILL.md`, at most 90 lines. Frontmatter: name, description (one line, at most 200
  characters).
- Body:
  1. When to use it.
  2. The roster and caps: point to tools/builders.conf, do not copy numbers.
  3. The loop: spec, failing tests first (protected), TEMPLATE brief with Ripple and May edit, slots.sh,
     build_pipeline.sh, the .result verdict line, the review panel, merge_run.sh.
  4. The debug recipe: reproduce headless; a red test; a fix; root cause in one line; a check that stops the class.
  5. **Prompt recipes** (the next section), pasted as written.
  6. Pointers to lessons.md (seed: LESSONS §4 lines that concern builders) and research-queue.md (empty template).
- Delete `.claude/skills/architecting-games`, `coding-gameplay` and `debugging-games`. Grep for references and
  repoint them to builders.
- Rewrite `.claude/skills/emergency-efficiency/SKILL.md` as a delta of at most 30 lines: one director chat; builders
  build; reviews by the calibrated lens; Claude merges; builders never merge or push to main (D3).

### Prompt recipes (paste into the skill)
Every brief, for any executor, fits in 60 lines:
- **Goal**: why, in one line.
- **Inputs**: exact paths and line ranges, then "read nothing else".
- **Steps**: numbered, each with an observable output.
- **Do NOT**: paths and actions.
- **Output contract**: exact format, maximum lines, where it is written.
- **Done**: conditions that can be checked.
- **Stop rules**: maximum rounds, and when to stop and report.
- **Budget**: maximum tool calls or turns.

Per executor:
- **Haiku** (subagent; large, mechanical, reading-heavy; it overthinks complex work):
  - one task type per run, <= 8 steps;
  - exact files and grep patterns with head_limit;
  - a fixed output template, with one worked example line;
  - "if unsure write UNSURE and the evidence, never guess";
  - list what NOT to report;
  - split big jobs into parallel runs over disjoint inputs;
  - no design choices; effort from calibration.
- **Sonnet** (session or subagent; strong when scoped, loops when the task is vague):
  - Opus makes the decisions first, so no open design questions are left;
  - give the acceptance tests or checks;
  - `/advisor opus`; a loop cap of 3 rounds;
  - "grep, then read the named lines";
  - the delegation briefs pre-written;
  - milestone-only reports; hand off at ~100k work tokens.
- **agy** (Gemini Flash; Godot UI and code with renders; not creative):
  - geometry, colour and size numbers plus the concept path for any visual;
  - first commit within 15 minutes (the idle watchdog);
  - GEMINI.md review_misses;
  - it never judges legibility or feel; renders are judged by the player lens.
- **DeepSeek** (Cloudflare via opencode; code plus tests; edits outside its scope):
  - an explicit Do NOT edit list and tests written first and protected;
  - small file sets;
  - spend logged by cf_build.
- **Free models** (opencode or OpenRouter :free; text only):
  - public content only; one-shot when possible; within the 50-a-day budget;
  - only the roles that passed calibration.
- **Reviewers** (lens agents):
  - inputs are the diff, the brief and the criteria only;
  - flag correctness and requirement gaps only;
  - <= 15 lines.

## Done
- Checklist lines P2.0, P2.1, P2.7 and P2.8 (builders and emergency only) are ticked with commits; any line left
  open has its reason after it.
- check.sh is green, the work is merged to main, and cal/planted and the cal worktree are deleted.
- HANDOFF Efficiency holds: "P2b: docs/briefs/p2b-art-eye-gate.md. Model: Sonnet + /advisor opus. Effort: medium."
- A USAGE row records this chat's window %. Then /handoff.
