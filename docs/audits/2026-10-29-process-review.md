# Process review: efficiency, workflow, pipelines (Feras asked 2026-10-29)
Read once; not loaded at session start. Numbers are measured in the row 12 chat (local_785ace8a) unless marked.

## 1. Where the tokens go (measured, this chat)
| What | Amount |
|---|---|
| Model calls (one per tool round-trip or reply) | 94, plus 2 advisor calls |
| Cache-read tokens (the whole context re-read on every call) | 14.4 M (avg ~150k a call) |
| Cache writes / fresh input / output | 149k / 0.2k / 48k |
| Fixed prefix before any work (tools 40k, MCP tools 23k, system 10k, memory 8k, skills 8k) | ~90k on every call |
| Context now | 191k |

**Cause chain:** cost ~= model calls x context size. Output and file reads are small next to it. Three things blew it up:
1. **Too many round-trips.** About 20 calls were waits and wake-ups for background jobs, plus four calls to fix one regex
   mangled by a heredoc. Worktree isolation also refused compound commands, which split one step into three.
2. **A fat fixed prefix.** 23k of MCP tools (Gmail, Drive, Docs, Cloudflare bindings, Rodin twice, OpenRouter, Blender)
   ride on every call, though this task used none of them except Calendar.
3. **Two tasks in one chat.** Your second request started at 190k context, so every call now costs about 2x what it
   would in a fresh chat. The rule "one task per chat" exists; it was broken by continuing here.
4. **Advisor calls** forward the whole transcript to a stronger model: two at 100-150k each.

**What is NOT the problem:** the docs. Always-loaded notes are 24 KB (~7k tokens), under 10% of the prefix.

## 2. How the system works today
```
 Feras ──(asks, decides, plays, makes art)──────────────────────────────────────────┐
   │                                                                                 │
   ▼                                                                                 │
 Opus chat (the father; one task per chat)                                           │
   1 reads HANDOFF top row ── VISION check ── Ripple + pre-mortem                    │
   2 writes a brief (docs/briefs, TEMPLATE) ──────────────┐                          │
   │                                                       ▼                          │
   │                         build_pipeline.sh <agy|cf|oc> (own worktree in game-wt) │
   │                           slots.sh: <=2 Godot runs, 1 text run, 3 GB floor      │
   │                           builder writes code + tests, commits                  │
   │                           check.sh -> build_gate.py -> PASS/FAIL/NOWORK/BREACH  │
   │                           FAIL: up to 2 free fix passes, then the gate again    │
   │                                                       │ PASS                     │
   │                                                       ▼                          │
   │                         cross_review.sh (other family, empty box, packet file)  │
   │                           oc/* run -> agy reviews (on)                          │
   │                           gemini/* run -> DeepSeek reviews (being calibrated)   │
   │                           -> .check/reviews/<run>-cross.md                      │
   │                                                       │                          │
   3 Opus gate: the table + WARN lines + risky hunks (Haiku pass if the diff is big) │
   4 visual work: eye_gate.sh -> review-player + review-feras (review_gate hook)     │
   5 merge to main, /handoff (HANDOFF, decisions-log, USAGE, calendar) ──────────────┘
 Hooks on every chat: token_handoff (200k/250k), pre_spend (paid calls), review_gate (renders), session_start (SYNC)
```

## 3. How to use it best (the rules that save the most)
1. **One task per chat, a fresh chat per request.** The cheapest call is the one with a small context.
2. **Batch.** One tool call that does three things beats three calls. Background jobs: start them, then keep working
   on something else instead of waiting turn by turn.
3. **Builders write, Opus briefs and gates.** A builder run costs Claude only the brief (~2k) and the gate read.
4. **Trim connectors per task** (you toggle them in the app; free): a code task needs none of Gmail, Drive, Docs,
   Cloudflare, Rodin, Blender, OpenRouter. That saves ~20k on every call, about 10-15% of a chat's cost.
5. **The advisor once, at the start**, on chats over ~100k; skip the closing call on small changes.
6. **Write code with Write/Edit, not heredocs** (a known lesson, broken again today: it cost 4 calls).

## 4. How CLAUDE.md and the skills represent it
| Piece | Holds | Verdict |
|---|---|---|
| CLAUDE.md (73/80 lines) | north star, start steps, tool-enforced rules, 5 judgment duties, lean process, owner limits | Good shape. It says "one task per chat" but nothing enforces it; the costs above are not in it. |
| HANDOFF / DECISIONS / LESSONS (auto-loaded) | queue, rules in force, traps | Lean (24 KB). HANDOFF is 58/60 lines: tight. |
| WORKFLOW.md (225 lines, 22 KB) | routing, departments, protocols, limits | The real manual. Long; only read in parts, so fine. |
| builders skill (12 KB) | how to run agy/cf/oc, lessons | Strong on recipes; it has no per-model profile (strengths, failure modes, measured scores). |
| handoff skill | the end-of-chat steps | Missing: the 5-part report to you, and the calendar update. Added today (section 7). |
| 15 persona skills (~4 KB each) | department voices | Listed name-only, so cheap. Fine. |
| Hooks (4) | the hard rules | They work. The token hook counts context, not calls x context, so it warns late. |

## 5. Row 12 verdict: who builds, who reviews
- **Build: agy first** (free, Gemini Flash; in race B it reached passing code in ~20 min). **cf (DeepSeek)** only when
  agy's quota is out: it is paid past the free tier, and in race B it edited a protected file (BREACH). **oc** stays
  for text.
- **Review: the other family as a free pre-pass, then Opus.** agy reviewing: 3/5 known bugs twice (10-28, 10-29),
  but 1 of 10 findings was harmful and 1 false, so Opus vets every finding before a builder gets it. DeepSeek
  reviewing: 0 findings blocks in 3 live runs today (it hit opencode's 32k output cap once, then printed nothing):
  off. agy's own runs get the calibrated nemotron :free lens next (row 12), never agy reviewing itself.
- **No parallel races.** Race B: two builders, same result, double the review. Logged 10-28; the data hasn't changed.
- **Keep or drop cross-review:** measure 5 runs in USAGE ("cross-review hits"). Fewer than 1 real bug a run on
  average -> drop it; Opus's gate alone costs less.

## 6. Roles (who does what)
| | Feras | Opus chat | Builders (agy, cf, oc) | Haiku / review-* agents |
|---|---|---|---|---|
| Decides | scope, story, art, spending, models, releases | nothing final: advises with a pick | nothing | nothing |
| Does | plays builds, makes art, logins, "spend ok" | plans, briefs, reviews, merges, MCP art work | code, tests, docs, reviews | big reads, review lenses |
| Reports | notes after each play | the 5-part report (below) + calendar | .result + log | a findings list |

**The 5-part report at the end of every chat** (handoff skill step 7): Done | Still open | When (calendar day) |
How (lane, who) | Your move vs mine.

## 7. Your new ideas: verdicts
| Idea | Verdict | Pick |
|---|---|---|
| Cloudflare classifier models for docs | The useful Workers AI models here are embeddings (bge), not sentiment classifiers: they find duplicate or superseded rules across docs (lesson: "a superseded rule lives on"). Free tier covers it. | Yes, a small builder row after M1 (docs/ideas.md). |
| Improve CLAUDE.md with the plugin | claude-md-improver gives a one-off audit. CLAUDE.md is already capped and checked, so the gain is small. | Once, in a fresh Sonnet chat, after M1. |
| Organize docs, skills, reports, roles | Sections 4 and 6 above; the 5-part report is now in the handoff skill. | Done today; no big reorganization (it costs more than it saves now). |
| Calendar for the plan | Already used (the 10-28 events). Now a handoff step: when the plan changes, update the next 3 days' events. | Done today (handoff skill). |
| Room for new ideas | docs/ideas.md: an inbox, never loaded at start, triaged into queue rows at the weekly plan. | Done today. |
| Save contexts on disk to dodge cache misses | It doesn't work: the prompt cache lives on Anthropic's servers and keys on the exact prefix. Replaying saved text re-sends it (a cache write, the dearer kind). HANDOFF.md is the right "saved context": small summaries, not transcripts. | No. Instead: see below. |
| Model-orchestration skill from Artificial Analysis | Good, but our own calibration beats benchmarks: we now have two known-bug sets (hook diff: 5 bugs; parser: 2). A model card per model = AA index numbers (fetched by a builder, D18) + our measured scores + failure modes. GLM 5.3 Flash etc. join only after a calibration run (D11). | Yes, a builder row after M1. |

**Cache and TTL, what actually helps:** this session's cache lives 1 hour, refreshed on each call. (1) Don't leave a
task idle over an hour mid-work: the next call re-writes the whole context. (2) Don't toggle connectors or settings
mid-chat: a changed prefix is a full miss. (3) Fresh chats are cheap to start (~90k prefix, mostly cached across
chats); long chats are what cost. (4) Fewer, bigger tool calls. (5) Compaction rewrites the cache: hand off before it.

## 8. Still open from row 12 (status at the end of this chat)
| Point | State |
|---|---|
| DeepSeek's live review | Failed: 3 runs on agy's parser, 0 blocks. Found and fixed a real runner bug on the way (2-dot diff pulled main's newer commits and MAP.md into the packet). DeepSeek is off as a reviewer; row 12 = a nemotron :free reviewer for agy runs (builder, free). |
| settings.json allow rule | Not needed today (the script runs). If a chat is ever blocked launching it, you add `Bash(bash tools/cross_review.sh:*)`. Chats can't edit it (refused as self-modification). |
| Real bug agy found (frame-name regex) | Fixed today with a test (review_gate.py anchors `^f\d{8}\.png$`). |
| The refused lesson line | Dropped; the point lives in decisions-log 10-29 instead. |
| Your main checkout 18+ behind | Your move: `bash tools/sync_main.sh` before Sunday's play. |

## 9. Critique (VISION check)
Three days have gone to process (rows 1, 12, 14) while M1, the thing VISION ranks first, hasn't started, and 83% of
the week is used. Pick: **process freeze until you have played M1** (Sunday). The only process work allowed before
then: trimming connectors per chat (your toggle, free) and fresh chats per request. Everything else waits in
docs/ideas.md.
