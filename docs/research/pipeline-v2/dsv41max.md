## 1. FINDINGS

**F1 [blocker] Middle tier is documentation-only; no red-test stage or lock.** Evidence: `SKILL.md:22-24` promises GLM max writes/locks red tests; `build_pipeline.sh:139,142-153` runs one builder session plus fix passes; no tests-only command exists. Fix: add `red_build.sh`/`--tests-only` using GLM max, commit only tests, write `.check/locked-tests.sha256`; hand run gets `--locked-tests`; gate verifies hashes and rejects test/prod mixing. Test: middle writes a prod file → reject; hand edits locked test → BREACH; hand implements → PASS.

**F2 [blocker] Pipeline executes builder-controlled scripts before the gate.** Evidence: `build_pipeline.sh:77` runs `$wt/tools/run_godot.sh`, `:82` runs `$wt/tools/map.py`, `:89-91` runs `$wt/tools/check.sh`; gate runs later at `:156`. A builder can edit `check.sh` to `exit 0`, or `map.py` to write a fake result. Fix: execute tooling from a pristine main/base copy, or hash-verify protected infra before execution; gate must BREACH any edit to `tools/check.sh`, `tools/map.py`, `tools/run_godot.sh`, `build_gate.py`, `.github`, rules. Test: builder edits `check.sh`/`map.py` to pass or touch a sentinel → pipeline must not execute it and must BREACH.

**F3 [blocker] Cost/finding scoreboard is false.** Evidence: `build_pipeline.sh:173` hard-codes `--cost 0 --findings 0`; `slots.sh:20-43` regexes logs that contain no token counts, so `cf_spend.csv` gets `?`; `builders.conf:26-27` uses USD/1M while Cloudflare bills neurons; `cf_build.sh:27` passes those rates. Also `:173` uses `python`, not `$py`, and swallows failure with `|| true`. Fix: capture usage from provider/opencode JSON/DB, log input/output tokens, neurons, USD, source, and `unknown`; sum build + every fix log + probes/reviews; use `$py`. Test: token fixture → nonzero; no tokens → `unknown`, never 0; two fix logs sum; neuron conversion fixture.

**F4 [high] Gate crash, builder exit, and stale `.result` are misclassified.** Evidence: `build_pipeline.sh:47-58` waits on PID but ignores exit code; `:156-159` defaults to `FAIL` when gate emits no `VERDICT` (traceback seen in row25-sync-dirty); `refuse()` at `:19` does not delete an old `$res` before `:22`. Fix: remove `$res` at start; capture builder rc; require exit 0 and commits; if gate rc≠0 or no verdict → `BREACH`/`GATE_ERROR`; never merge. Test: stub gate traceback → BREACH; builder exits 7 with no commit → NOWORK/FAIL; pre-existing PASS + refusal → no stale PASS.

**F5 [high] Idle 25/31 minutes is caused by watching commits only.** Evidence: `build_pipeline.sh:47-57` kills only after `idle_sec` with no commit; `:62-67` accepts committed work after idle; `builders.conf:8` sets 25 min. Builder hangs after last commit, so the watchdog is the only exit. Fix: after at least one commit, kill when log/process activity is unchanged for 3–5 min; add an absolute run timeout; log the reason. Test: stub builder commits then sleeps forever → pipeline finishes quickly and gates the commit, not after 25 min.

**F6 [high] Cross-review and merge routing are branch-prefix/manual, not author-model based.** Evidence: `cross_review.sh:17-24` maps `gemini/*`→cf and `oc/*`→agy, both using `CF_MODEL`; no GLM reviewer path, contradicting `SKILL.md:26`; `merge_run.sh:6-7` defaults to `gemini`, so cf runs need manual `oc`. Fix: record author/model/family in `.result`; select reviewer by author family (DeepSeek/agy→GLM max; GLM→DeepSeek max; fallback different family); infer merge prefix from result/branch; verify `checked` is an ancestor of the branch. Test: fake cf/agy/glm results select expected reviewer; merge finds branch without manual prefix.

**F7 [high] Proof is plumbing-only.** Evidence: owner 11-02: 3 `RUN_KIND=py`, cf only, 0 new test files, no Godot/agy; `build_pipeline.sh:139` is one session. Fix: run the matrix in §3; gate must require ≥1 locked test for code tasks or explicit `NO_TEST_REASON`. Test: zero-test code task → BREACH unless waived.

**F8 [med/high] CI wait can select the wrong run and times out before CI.** Evidence: `handoff.sh:10-21` uses `gh run list --commit <sha> --limit 1`; one workflow can still have push + pull_request + dispatch/rerun runs for the same SHA; `:21` waits 600 s while `check.yml` allows 15 min; `handoff.sh:4-6` pushes main before CI. Fix: filter `--workflow check.yml --event push`, select the target run by databaseId/status, wait ≥ CI timeout + margin, push main only after success. Test: stub old success + new queued for same SHA → waits new; queued 11 min then success → passes; failed CI → main not updated.

**F9 [high for oc path] `OC_MODEL` defaults to a spent free route.** Evidence: `builders.conf:17` `opencode/deepseek-v4.1-flash-free`; `build_pipeline.sh:51,70` only reacts after seeing the exact quota string, otherwise idle; `cf_build.sh:22` bypasses it. Fix: remove the spent default; require explicit model or use a paid/calibrated route; preflight smoke/quota check before launch. Test: stub quota/error → immediate nonzero NOWORK, not 25 min.

**F10 [med] Stale duplicate plugin entries are environment hygiene, not pipeline code.** Evidence: owner 11-02: 8 entries in `~/.claude/plugins/installed_plugins.json`, 6 deleted/other worktrees; `merge_run.sh:22-24` removes worktrees but no plugin cleanup. Root cause: local-scope install per worktree, never pruned. Fix: one project-scope install; prune local entries whose path is gone; cleanup hook after worktree removal. Test: temp HOME, create/remove worktree → exactly one live entry; `claude plugin list` no duplicates.

**F11 [med] Scoreboard effort and fix-pass counts are wrong.** Evidence: `build_pipeline.sh:171-172` parses effort from model name; `deepseek-v4.1-flash-1017` logs `-` though `opencode.json:31-38` sets max; `fast` logs `-` though it is none; `:141-153` increments `fix` before the guard, so exhausted failures log 3 when only 2 passes ran. Also `:147` says “<=45 min” but `run` still uses 25-min idle. Fix: pass explicit effort/model per run; count actual fix runs; separate build/fix model; align timeout text. Test: always-fail stub → 2; fast → none; 1017 → max.

**F12 [high] Merge can include unreviewed commits.** Evidence: `merge_run.sh:15-20`: only exact checked-tip fast-forwards reuse the gate; otherwise it merges the whole branch and runs only `check.sh`, not `build_gate`/cross-review. Fix: require branch tip == checked, or re-gate/review the extra commits; assert checked is an ancestor; refuse otherwise. Test: add a commit after PASS → merge refuses or re-gates; unrelated branch with PASS result → refuse.

**F13 [med] Base-red check can be skipped and is incomplete.** Evidence: `build_pipeline.sh:109-111` warns and continues when `base_red.py` times out; builders skill says GDScript/slow toys are not seen. Fix: timeout → refuse for code runs unless explicit override; cover all test kinds. Test: base_red timeout → exit 3; GDScript sibling red test → refused.

**F14 [high] `leftovers` commits everything with `git add -A`.** Evidence: `build_pipeline.sh:94-97,140,153,155`; opencode has bash/edit allow (`opencode.json:9-17`). A builder can commit `.env`, tokens, generated blobs, or malicious files. Fix: allowlist paths, secret-scan diff, never commit auth/env/artifacts; gate scans. Test: seed `.env`/fake key → BREACH.

**F15 [high] Hidden costs/quota are outside slots.** Evidence: `builders.conf:2-5` caps builds only; `cross_review.sh:62-63` logs spend after the call; `cf_probe.py`/critic, retries, forced review round, and fix logs are not reserved or summed; `cf_build.sh:2` says no $ cap. Fix: global CF ledger with reservations for every call, concurrency cap across builds+reviews+probes, preflight budget; archive each fix log. Test: 3 reservations with CAP_CF=2 → third refused; two fix logs sum in spend.

**F16 [med] “Sonnet” is hard-coded as the head.** Evidence: `SKILL.md:3,13`; builders skill says Opus decides/Sonnet executes; docs conflict. No code selects the head model, so this is docs/role semantics. Fix: canonical “Claude head (Sonnet or Opus per session)”; head owns design; `/advisor opus` when needed; update skill frontmatter/table/rules/CLAUDE.md. Test: doc lint greps for “Sonnet high” as head; only explicit model-selection section may name models.

## 2. Owner’s listed items

**(a) CI wait.** Not a bug in the narrow case: one workflow and one run per SHA means `--limit 1` works. It is a latent correctness bug because the same SHA can have push/PR/dispatch/rerun runs; “first” is not “the check for this push.” The real active bug is `600 s < 15 min` CI timeout and pushing main before CI. Smallest fix: filter `--workflow check.yml --event push`, select the run by ID/status, wait ≥ 15 min + margin, push main only after success; test with two same-SHA runs.

**(b) Duplicate plugins.** Not a pipeline-code bug; it is environment state. Root cause: local-scope plugin install per worktree, never pruned after `merge_run.sh:22-24` removes worktrees. Smallest fix: one project-scope install, prune local entries with missing paths, cleanup after worktree removal; test in temp HOME.

**(c) `OC_MODEL` spent default.** Real trap. `builders.conf:17` defaults to a spent free route; `cf_build.sh` is the correct paid route, not a bug. Fix: remove the spent default, require explicit model or paid route, preflight quota/smoke before launch; test immediate failure on quota.

**Idle run.** Root cause: builder hangs after last commit; pipeline watches commits, not process/log activity. Fix: post-commit inactivity kill after 3–5 min, absolute timeout, capture exit code; test commit-then-sleep.

**Cost measurement.** Root cause: opencode default logs contain no token counts; `slots.sh` regexes them; `build_pipeline.sh:173` hard-codes 0; units are USD not neurons; probes/reviews/fix logs are omitted. Fix: provider/JSON/DB usage capture, explicit schema, neurons+USD+source+unknown, sum all stages.

**Sonnet→Claude.** Root cause: role name tied to a model in docs/skills; no code dependency. Fix docs to “Claude head,” allow Sonnet/Opus per session, remove “Sonnet never invents design” or replace with “head owns design; use Opus advisor when available.”

## 3. Proof plan

Run set:
1. **Godot/agy**: small GDScript/UI change with a GDScript test/render, `RUN_KIND=godot`, agy builder, cf/GLM cross-review. PASS.
2. **Locked red test by middle**: GLM max tests-only commit; head reads/locks; DeepSeek high implements; gate verifies hashes. PASS.
3. **CF max + fix pass**: force an initial check failure; max fix pass; measure archived logs and cost. PASS.
4. **Parallel two parts**: two worktrees, each own red test; merge by hand; no sibling-red failure. PASS.
5. **Deliberate failures, one per gate**: locked-test edit → BREACH; `check.sh`/`map.py` edit → BREACH/no execution; gate traceback → BREACH; cross-review invalid/no block → INVALID/no merge; merge wrong prefix/stale result → refused; same-SHA old CI success + new queued → waits new; builder commit+sleep → quick idle kill, committed work gated.

Measure: wall time, idle time, per-stage tokens/neurons/USD, fix passes, new test count, red-on-base/pass-on-head, cross-review findings confirmed, worktree/plugin cleanup, memory/CPU, CI wait. Pass criteria: every expected verdict word; no merge/main push on failure; cost known and nonzero (or explicit unknown); no idle >5 min; locked tests unchanged; reviewer family differs; docs updated. Zero-test code task must fail unless explicitly waived.

## 4. DO / DON’T

**DO**: pin base to origin; one task per worktree; smoke each route; read `.result` first word and `checked` commit; lock tests and protected infra; run checks in foreground; archive every build/fix log; capture provider usage; use `$py`; require different-family review; treat gate crash as BREACH; verify CI workflow/event; prune worktrees/plugins; secret-scan leftovers.

**DON’T**: trust builder stdout/logs; merge on PASS without checked commit; hard-code cost 0/findings 0; default to spent free routes; let builders edit tests, `check.sh`, `map.py`, `run_godot.sh`, rules, or CI; execute builder-modified scripts; push main before CI; rely on `--limit 1`; price neurons with USD rates; run probes/reviews outside quota accounting; `git add -A` blindly; assume `.result` is current.

## 5. What the head likely missed

- **Shared inbox is writable by builders.** `build_pipeline.sh:158` passes `$root/inbox`; `opencode.json:13-16` allows absolute `C:\dev\game\inbox\*` from any worktree. A builder can plant files that influence later gate/review work. Use per-run inbox or deny external writes.
- **Prompt injection / permission traps.** `opencode.json:9-17` allows bash/edit; agy runs `--dangerously-skip-permissions --sandbox` (`cross_review.sh:39`). Worktrees are not a security boundary; briefs, patterns, inbox files, and repo content can inject commands. Deny network/secrets where possible; scan diffs.
- **Test-runner gaming.** Protecting test files is insufficient: `conftest.py`, pytest config, `check.sh`, `map.py`, fixtures, `.github` can be edited. Gate must protect test infrastructure, not just tests.
- **Hidden costs.** Critic/probes, cross-review, forced review round, retries, fix logs, parallel runs, Godot import, and large 384k-output runs are not in `runs.csv`; `cf_spend` only covers some calls. Cloudflare daily neurons/rate limits can be hit by 2 builds + review + probe.
- **Windows/git-bash traps.** `build_pipeline.sh:173` uses `python`, not `$py`; `:82` leaves `$py` unquoted; `xargs -r`, `timeout`, `powershell`, path separators, CRLF, locked worktree removal, and `gh` auth can fail. `merge_run.sh:23` has no retry for locked files.
- **Weak builder wins.** A builder can add trivial tests, delete tests, weaken assertions, edit test config, commit WIP garbage, or exploit `base_red` blind spots. Require red-on-base, mutation/negative cases, and locked manifests.
- **Scoreboard semantics.** `?` in `cf_spend` is not “zero”; `runs.csv` has no `cost_source`/`neurons`; `real_findings` is never fed from review. Distinguish unknown from zero.
- **Cross-review packet size.** Full diff + skill + rules can exceed context; forced round doubles cost and may still be invalid. Cap diff size, require file list, fail closed.

## 6. Prioritised plan

1. **Protect infra (blocker).** Brief: run `check.sh`, `map.py`, `run_godot.sh` from pristine copy or hash-verify; gate BREACH on protected-path edits; secret-scan leftovers. Acceptance: edited `check.sh`/`map.py`/test → BREACH/no execution; `.env` → BREACH.
2. **Fix result/gate semantics (blocker).** Brief: remove `$res` at start; capture builder rc; gate rc/no verdict → BREACH; use `$py`; no `|| true` swallowing. Acceptance: traceback → BREACH; exit 7 no commit → NOWORK; stale PASS + refusal → no result.
3. **Cost telemetry (blocker).** Brief: provider/JSON/DB usage capture; schema tokens/neurons/USD/source/unknown; sum build + each fix + probes/reviews; explicit effort. Acceptance: fixtures for token/no-token/two-fix/neuron; `runs.csv` no hard-coded 0.
4. **Middle red-test stage (blocker).** Brief: tests-only GLM run, manifest, hand `--locked-tests`, gate hash check, require ≥1 test or waiver. Acceptance: prod file in tests-only → reject; test edit → BREACH; PASS only with locked red test.
5. **Idle completion (high).** Brief: post-commit log/process inactivity kill, absolute timeout, reason. Acceptance: commit-then-sleep finishes <5 min; committed work gated.
6. **Cross-review/merge routing (high).** Brief: record author/model; reviewer matrix; auto prefix; checked ancestor; re-gate extra commits. Acceptance: cf/agy/glm matrix; extra commit after PASS → refuse/re-gate.
7. **CI wait (med/high).** Brief: filter workflow/event, wait ≥15 min, push main after success. Acceptance: same-SHA old success + queued → waits new; 11-min success passes; failed CI → main unchanged.
8. **Environment/defaults (med).** Brief: remove spent `OC_MODEL` default/preflight; prune plugin local scopes/worktrees; retry locked worktree removal. Acceptance: quota stub immediate fail; temp HOME plugin count one.
9. **Docs Sonnet→Claude (med).** Brief: canonical Claude head, remove hard-coded Sonnet/Opus rules, doc lint. Acceptance: grep finds no “Sonnet high” head; design authority is head-owned.
10. **Proof matrix (gate).** Brief: execute §3, record evidence, fix failures before claiming pipeline v2. Acceptance: all PASS/deliberate-failure criteria met; no merge on failure; cost known; no idle >5 min.