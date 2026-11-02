# Foremen and context hygiene (Feras 11-02)
The head's context is the expensive resource. Everything below keeps it lean without lowering quality.

## Scripts are the foremen
| Stage | Foreman | What the head sees |
|---|---|---|
| launch, wait, check, fix passes, gate | `tools/build_pipeline.sh` via `tools/cf_build.sh` | a notification, then the report |
| any finished part | `python tools/part_report.py <task>` | at most 15 lines of 160 characters: word, model, checked sha, idle, details, cost, flags, next step |
| test-first stage | `EXPECT_RED=1` scope run, `tools/scope_gate.py`, `tools/lock_tests.sh` | SCOPED or REJECT, then the tests themselves (always read in full) |
| plan checks | `tools/ripple.py`, `tools/parts_plan.py` | OK or one line per problem |
| merge | `tools/merge_run.sh` | one line |

## The one subagent: flag confirmer (Haiku low)
Prompt shape, one task, 8 steps at most: "For each flag in <file>, grep the named line in the code. Reply one line each: `flag | evidence line | holds or not`. Reply UNSURE with the evidence when unsure. Do not judge correctness, suggest fixes or read anything else." The head adjudicates only the "holds" lines. A Sonnet foreman is allowed at high but earns its keep only for a chunk of noisy work the scripts cannot do.

## Rules that keep the head's context clean
- Noisy command -> `cmd > file 2>&1; tail -n 15 file`. Never cat a log, a diff or a check output; read an offset.
- Summaries come from scripts first, `cf_probe.py --effort none` second (neurons), Haiku low last.
- Builder output never goes into the chat. The head reads: part reports, locked tests in full, flags that hold, risky hunks by offset.
- One task per head chat, finished at full quality; `/handoff` at the end or ~85% of the 5-hour window. Do not churn CLAUDE.md or skills mid-chat (it breaks the prompt cache).
- State lives in files (plan file, `.result`, runs.csv), so a fresh head resumes from them.
