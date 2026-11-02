# Proof: what has been shown, what each run must measure (row 26, Feras 11-02)
"Proven" means measured on real runs, not that the plumbing ran. Row 25 proved plumbing only (3 small Python runs, cf only,
0 new tests, no Godot, no agy); cost read 0 or `?`; one run sat idle 25 of 31 minutes. The v2 fixes are in changelog.md.

## Read the scoreboard
`docs/runs.csv`: date, task, worker, effort, gate, fix_passes, minutes, cost, real_findings, tokens_in, tokens_out, usd_est,
cost_source, idle_min. `?` is unknown (never 0). usd_est is tokens x the rates in builders.conf (an estimate: Cloudflare bills
neurons). `python tools/part_report.py <task>` shows one run's row beside its result.

## Proof batch (run in this order; one smoke call per route first; state the list before running)
| Run | What | Pass when |
|---|---|---|
| P0 | the same prompt to GLM-5.3 at `none` and at `max` through cf_probe | the two completion/reasoning token counts differ (the effort label does something) |
| P1 | agy builds a small Godot change with a Godot test and a render | PASS, a new test red on the base, render judged by the player lens |
| P2 | scope run (GLM) -> head reads -> lock_tests -> DeepSeek low with a Pattern; the same scope brief also to DeepSeek max (A/B) | SCOPED, hand PASS without editing tests; the better test set survives a seeded mutation |
| P3 | cf max with a forced check failure | one fix pass, tokens of build + fix summed in runs.csv |
| P4 | stub failures: crashed gate, edited locked test, commit-then-sleep, stale PASS, forged PASS | ERROR, BREACH, quiet kill < 6 min with commits gated, no stale PASS, merge_run refuses a forged result |
| P5 | cross-review with the author-different reviewer; the optional second lens | reviewer family != author family; count flags the second lens added |
| P6 | a seeded defect under a green test | caught by the gate, a lens or the head (the only run that measures output quality) |

## Pass criteria for the batch
Every expected result word; no `?` cost rows for cf runs; no idle > 6 minutes; zero gate tracebacks; locked tests unchanged; runs.csv
usd_est within the Cloudflare dashboard's order of magnitude; peak memory noted before raising any cap. Results go to runs.csv and
one line each in changelog.md. Results of 11-02 so far are in changelog.md.

## Results so far (11-02, one Sonnet-high chat; details and costs in changelog.md)
| Run | Result |
|---|---|
| P0 | Done. GLM `none` 998 tokens / 7 s vs `max` 23,121 / 98 s, same right answer: the label works; `max` is for work that earns it. |
| P1 | Done. agy built a Godot helper behind a locked GDScript test: PASS, the full Godot suite 584 passed. It exposed a flaw: the quiet watchdog cut agy 310 s after its commit (agy's log is empty until it finishes); fixed (streaming builders only), tested. Not shown: a render judged by the player lens (the helper has none); agy has no cost meter (`?`). |
| P2 | Done, n=1. Scope run -> head reads every test -> lock_tests -> DeepSeek low builds: PASS. A/B of the test writers on the same brief: DeepSeek max set killed 11 of 12 seeded bugs and passed the correct code; the GLM set failed the correct code. |
| P3 | Covered by a real run, not forced: the ripple build needed a fix pass and its build + fix tokens were summed per worktree (99k in / 27.5k out). |
| P4 | Covered by the suite, not by hand: crashed gate -> ERROR, stale PASS removed, commit-then-hang quiet kill, forged or missing VERDICT refused, a startup collision retried, an agy log never quiet-killed (test_run_state, test_routing, test_oc_start_retry, test_agy_quiet). |
| P5 | Done. The DeepSeek-built tool was reviewed by GLM max (family chosen from the .result): 3 of 5 flags were real bugs, now fixed with tests. |
| P6 | Done as 12 seeded one-line bugs on the P2 tool (above), and the cross-review above found 3 unseeded ones. A seeded bug in a Godot run is still open. |
Open: the second lens (XR_DUAL) is not built; the A/B is one task; agy cost is unmetered; peak memory with three cf runs plus a check touched the 2,000 MB floor once (a Godot run was refused, then fine).
