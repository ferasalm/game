# How We Work
Updated whenever docs/WORKFLOW.md Protocols change.

## The whole system (v3, row 24)
Orange = your moves. The row flow: `queue row -> brief -> red test -> builder run -> gate -> review -> merge -> /handoff`.
```mermaid
flowchart TB
    subgraph You["Feras"]
        Decide["Decides: scope, story, art, models, releases"]
        Spend["Says 'spend ok' for a paid call"]
        Play["Plays a gated build on PC and phone"]
        Notes["Writes notes"]
    end
    subgraph PM["pm plugin"]
        Queue["queue row: top row first"]
        Handoff["/handoff: updates queue and moves"]
    end
    subgraph Lead["Lead (Claude)"]
        OpusPlan["Opus: plans and writes specs"]
        SonnetExec["Sonnet high: executes, briefs and red tests"]
        HaikuWait["Haiku medium: launches and waits on builders"]
        OpusGate["Opus: gates diffs and signs off"]
    end
    subgraph Pipe["Builder pipeline (agy, nv, oc)"]
        Brief["brief"] --> RedTest["red test"]
        RedTest --> BuildRun["builder run (agy, nv, oc)"]
    end
    subgraph Studio["studio plugin"]
        Gate["gate: build_gate, check.sh"]
        Review["review: review-code, review-player, cross-review"]
    end
    Merge["merge to main"]

    Decide --> Queue
    Queue --> OpusPlan
    OpusPlan --> SonnetExec
    SonnetExec --> Brief
    BuildRun --> HaikuWait
    BuildRun --> Gate
    Gate --> Review
    Review --> OpusGate
    OpusGate --> Merge
    Merge --> Handoff
    Handoff --> Play
    Play --> Notes --> Queue
    Spend -.-> SonnetExec
    classDef feras fill:#f6a04d,stroke:#8a4b00,color:#000
    class Decide,Spend,Play,Notes feras
```

## Roles
| | Feras | Opus | Sonnet high | Builders (agy, nv, oc) | Haiku / plugins |
|---|---|---|---|---|---|
| Decides | scope, story, art, spending, models, releases | architecture, plans, final sign-off | execution plan | nothing | nothing |
| Does | plays builds, makes art, "spend ok" | writes specs, gates diffs, reviews | writes briefs & red tests, coordinates | code, tests, docs | launches/waits, studio reviews, pm queue |
| Reports | notes after each play | signs off | status | .result + log | review findings |

The 6-part report at the end of every chat: Done | Still open | When (calendar day) | How (lane, who) | Your move vs mine.

## Cost rules
Cost = model calls x context size (each call re-reads the whole chat from cache at ~1/10 price).
- A new multi-step task opens a fresh chat; a follow-up of up to ~10 tool calls stays (its cache is cheaper).
- Parallel tool calls in one message; never chained shell (the worktree guard refuses it).
- Builders write, Opus briefs and gates: a builder run costs Claude only the brief and the gate read.
- Waiting on a builder: the cache waker (tools/wait_run.sh) wakes the chat at 50 min so the 1-hour cache never
  expires; an overnight run hands off at launch instead.
- Connectors: Gmail, Google Docs, the second Rodin and Cloudflare bindings are off; Drive stays (Feras 10-29). Never
  toggle connectors mid-chat (a changed prefix is a full cache miss).
- The advisor only with Feras's OK. Scripts go through Write/Edit, never python heredocs (a hook blocks those holding a backslash).
- Hand off when the chat's task is done, at ~85% of the 5-hour window, or past the soft 300k context line once the current step is done (Feras 11-05).

## Who syncs, where you see things
- Syncing: the father chat. Children work in their own worktrees (one writer per set of files, so no conflicts); the
  father merges each, runs every check, merges to main and updates your checkout (sync_main.sh).
- Reports: feras/BRIEFING.md (newest first) at every /handoff; the chat's last message; your calendar's "Your moves
  today:"; HANDOFF "Open points" for anything agreed but not done, with its owner.
- Every problem or fix Claude names carries a status: done | in progress | planned (when) | not planned | waiting on
  Feras.

## The week
HANDOFF.md "This week" and Feras's calendar ("Your moves today:" events) hold it; this page never copies it.
