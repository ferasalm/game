# 1. Findings

**F1 BLOCKER — The middle tier does not exist.** SKILL.md:3,15,23 claims GLM max "scopes and writes red tests" as a stage; build_pipeline.sh:139–158 runs one session that implements the brief, then check.sh, then up to FIX_PASSES fix passes, then the gate. A red-test run cannot survive this pipeline: its own check fails on the red tests and fix passes are fed those FAIL lines and will "fix" the tests (build_pipeline.sh:142–153). builders/SKILL.md loop step 2 contradicts it outright ("tests written or locked by Claude"). Fix: either docs-only (head writes tests, matching builders skill) or an `EXPECT_RED=1` mode: skip check, verify ≥1 new test exists and fails on the base, write a RED result; hand run then uses the tests branch as base. Test: proof run R2 (§3).

**F2 BLOCKER — The gate crashed on a FAIL run and the pipeline masked it.** row25-sync-dirty Traceback; build_pipeline.sh:159 turns a missing VERDICT (crashed gate) into a plain FAIL. The hard quality gate's failure path is untested. Fix: fix the crash; gate fixture matrix (PASS/FAIL/dirty/BREACH/stub) in the py check; pipeline writes GATE-ERROR and exits 2 on Traceback output. Test: fixtures green in CI; deliberate FAIL yields a clean checklist.

**F3 HIGH — The scoreboard measures nothing, and hides the worst runs.** build_pipeline.sh:173 hard-codes `--cost 0 --findings 0`; idle_exit (:71–73) and refuse (:19) exit *before* :173, so NOWORK/REFUSED runs — exactly the idle waste — never appear in runs.csv. The runs row is also written before cf_build.sh:27 parses spend (wrong order, no wiring). Fix: compute cost from the spend parser, append rows for NOWORK/REFUSED, feed findings from cross_review output. Test: stub run leaves numeric rows; NOWORK stub leaves a row.

**F4 HIGH — Spend capture is impossible from opencode logs.** slots.sh:20–36 regexes need token fields the default opencode format never prints (the `?` rows; cf_probe rows are fine because probes parse their own output). Fix: read usage from opencode v2's own DB (path known: builders.conf:14) via a small oc_usage.py, or switch oc to a format that emits usage. Test: one cf build → integer token row, no `?`.

**F5 HIGH — A hung builder costs the full IDLE_MIN.** row25-base-red: 25 of 31 min idle; the only exits are process exit or the 25-min commit watchdog (build_pipeline.sh:56), despite the known pattern (:62). Also the first build run has no timeout (:139) while fix passes do (:153). Fix: kill on log-quiet (no commit AND log size unchanged ~8 min) — committed work still goes through leftovers/idle_exit; add a first-run OC_TIMEOUT. Test: stub that commits then sleeps dies ≤10 min with its commits gated.

**F6 HIGH — `.result` is forgeable.** Builders run with bash allowed (opencode.json:10–11), the result path is a predictable sibling of the worktree (build_pipeline.sh:14), and merge_run.sh:12–17 trusts the file: a builder can `echo PASS` plus `checked <tip>` and get an ff-merge reusing a check that never ran. Fix: builder bash allowlist (git, tools/check.sh only), final .result written atomically after the gate, merge_run requires the gate checklist section. Test: red-team stub writes fake PASS; merge refused.

**F7 MED — Cross-review picks reviewer by branch prefix, not author.** cross_review.sh:17–24 (gemini/→cf, oc/→agy, cf reviewer always CF_MODEL) contradicts SKILL.md:25. DeepSeek work gets Gemini (not GLM as documented); "DeepSeek reviews GLM" is unreachable. Fix: pass author model (already in the .result) and map it. Test: GLM run's xr log shows a DeepSeek reviewer.

**F8 MED — handoff CI cap 600s < workflow timeout 15 min** (handoff.sh:21 vs check.yml `timeout-minutes: 15`) → false `fail ci` on any run over 10 min. Fix: cap ≥ 960s. Test: ~12-min CI run passes handoff.

**F9 MED — No total cap on the first build.** Any commit resets the idle mark (build_pipeline.sh:49); a builder committing every <25 min runs forever. Fix: BUILD_TIMEOUT (90 min) → NOWORK. Test: 20-min-commit stub stopped at cap.

**F10 MED — base_red timeout is warn-only** (build_pipeline.sh:109–111): an unchecked base proceeds — the rows-23/24 class it exists to stop. Fix: refuse (or retry once). Test: red-base stub → refused.

**F11 MED — "Sonnet" identity hard-coded** (SKILL.md:3,13; builders skill; CLAUDE.md), with two inconsistent stories (Opus plans vs Sonnet head). Fix: one sweep, roles not models; update the YAML description — it drives skill matching. Test: `grep -rin sonnet` returns only deliberate routing advice.

**F12 LOW — merge_run defaults prefix gemini and fails cf runs** (merge_run.sh:6–7); the prefix is already in .result line 1. Fix: parse it. Test: merge a cf run with no argument.

**F13 LOW — Effort is regex-from-name** (build_pipeline.sh:171–172): bare 1017 (=max, opencode.json:31–38) and `fast` (=none) both log "-". Fix: explicit model→effort map. Test: default-model run logs effort=max.

**F14 LOW — Spend math is wrong currency**: USD-per-token rates (builders.conf:26–27) against neuron billing with a 10k/day free allowance (cf_build.sh:7, SKILL.md:32). Fix: label USD as estimate, price in neurons, add a daily-budget check. Test: one day's cf_spend reconciles with the dashboard.

**F15 LOW — Stale duplicate plugin entries** (owner item b, below).

# 2. Owner's items

**(a) CI wait — not a bug as stated.** One workflow, push to main: `gh run list --commit <sha> --limit 1` can only return that commit's check run; re-runs show queued, which the loop handles. The real defects are adjacent: the 600s cap under the 15-min timeout (F8), and it becomes a genuine bug the day a second workflow appears. Smallest fix: add `--workflow check.yml` to the HANDOFF_CI default, raise the cap to 960s.

**(b) Plugin duplicates — real, low.** Root cause: kaizen is installed scope-local keyed by path; the pipeline creates/destroys worktrees (merge_run.sh:23) without registry cleanup, so deleted worktrees leave entries that may double-fire hooks. Fix: prune installed_plugins.json to existing paths once, install at project scope only, prune after worktree removal. Check: after one merged run, `claude plugin list` shows one kaizen.

**(c) OC_MODEL — real, low.** builders.conf:17 is a stale free-route default; the oc builder launches and only the in-run quota grep catches it (build_pipeline.sh:51), wasting a slot and up to IDLE_MIN. Fix: point the default at a live route or pre-flight a 1-token probe that refuses at launch.

**Idle run.** Root cause: opencode v2 doesn't exit after its last commit (known, :62), and "no commit" is the only liveness signal. Smallest reliable fix: the F5 log-quiet kill — it distinguishes "slow but working" (log growing) from "committed and hung" (log frozen) without shortening IDLE_MIN for legitimately slow models.

**Cost measurement.** Three stacked causes: hardcoded zeros plus NOWORK/REFUSED rows never written (F3), no token counts in the logs the regexes read (F4), token-USD rates on neuron billing (F14). Fix F3/F4 first; F14 makes the number honest.

**Sonnet→Claude.** Root cause: model identity instead of role, in three doc layers, with two stories. Fix: one wording — "the head is this session's Claude model; design decisions need Opus-class judgment — a lighter session routes design questions to /advisor opus or Feras" — sweep SKILL.md frontmatter and body, builders skill, CLAUDE.md. No code change. Test: grep clean; skill triggers correctly from an Opus session.

# 3. Proof plan

Preconditions: F1–F6 fixed; one smoke per route. Every run gets a full runs.csv row. ~8 runs, mostly BUILDER_CMD stubs (free, deterministic):

- **R1 Godot + agy**: real feature brief, RUN_KIND=godot, ≥1 new GDScript test, render judged by the player lens; merge with no prefix argument. Optional cf-Godot twin if the day's neurons allow.
- **R2 Middle tier**: GLM max authors red tests (EXPECT_RED), head reads and locks, DeepSeek low + Pattern implements.
- **R3 Deliberate FAIL**: brief whose test contradicts its Do-NOT-edit list. Expect: FAIL word, no traceback, readable checklist, exit ≠ 0, ≤ FIX_PASSES.
- **R4 Deliberate BREACH**: stub edits a protected test. Expect: BREACH.
- **R5 Deliberate NOWORK**: stub never commits; second stub prints OC_QUOTA_MSG. Expect: NOWORK + reason, both logged.
- **R6 REFUSED**: base holds a red tool test the brief doesn't name; plus the base_red-timeout path. Expect: exit 3, no .result.
- **R7 Red-team**: stub writes a fake PASS .result mid-run. Expect: merge_run refuses.
- **R8 Seeded defect**: stub applies a subtle known bug under a green test. Expect: gate, cross-review, or head catches it; the only run measuring priority 1.

Measure per run: minutes, idle minutes lost, fix passes, in/out tokens, USD (labelled estimate), forced review rounds, findings raised vs confirmed, head Claude tokens for the batch. Batch pass: 100% correct result words; zero gate tracebacks; no `?` spend rows; runs.csv cost equals cf_spend sums; hung-commit stub killed ≤10 min; reviewer family ≠ author family every time; R8's defect caught; handoff survives a ≥12-min CI run.

# 4. DO / DON'T

**DO**: read the whole PASS .result (checklist, commits, diffstat) and the diff, never the summary alone; keep Do-NOT-edit and Tests sections in every brief; run slots.sh and one smoke per route before a batch; test the pipeline with BUILDER_CMD stubs; treat every WARN as an action item; log real findings back into runs.csv; prefer refusing over warning; prune plugin/worktree garbage at merge time.

**DON'T**: trust opencode stdout or exit 0 — only the .result word decides (SKILL.md:34); let a builder touch tools/, .github/, opencode.json, .claude/, docs/briefs (verify the gate enforces this — see §5); merge anything the head didn't review; run the free oc route while spent; relax IDLE_MIN instead of applying F5; batch-launch without checking the day's neuron spend; trust the effort column before F13; hand off to main without CI green.

# 5. What the head likely missed

- **Forged .result** (F6): the head assumed file provenance.
- **Builders can push**: git credentials are global and builder bash is allow-all; "builders never merge or push" is prose. GitHub branch protection on main is free and caps the blast radius.
- **Secret exfiltration**: opencode's auth DB (~/.local/share/oc-v2) holds the Cloudflare key; builder bash can read it and curl it out — "web denied" blocks a tool, not the network. Keep the key low-privilege and rotated; bash allowlists fix both this and the above.
- **Unverified assumption**: that build_gate protects tools/ and CI files. If not, a builder edits check.sh, passes its own check, and the gate green-lights it.
- **MAP.md is excluded from the review diff** (cross_review.sh:32): a builder can hide content there from the reviewer.
- **NOWORK/REFUSED never reach the scoreboard** (F3): a clean CSV masks the idle waste the owner is complaining about.
- **Neurons are shared**: 2 cf slots + cross-reviews at max + GLM critic probes + smoke calls all draw on the 10k/day, then silently pay ("no $ cap", cf_build.sh:2).
- **agy quota death looks like row25** (25-min idle); the quota grep only knows opencode's message.
- **Windows**: kill_tree can orphan node.exe children → locked worktrees (merge_run.sh:23 fails *after* the merge is already in), RAM creep the MIN_FREE_MB start-check never sees, unbounded v2 DB growth.
- **Context mismatch**: GLM's 200k (opencode.json:27) vs DeepSeek's 1M — a brief+skills paste that fits one can truncate the other silently.
- **Forced review rounds** (cross_review.sh:57–61) double review cost on format misses — count them.
- **handoff pushes to main before CI** (handoff.sh:1–5): `fail ci` leaves main red.

# 6. Plan

- **S1 Gate hardening (F2)**: fix the crash, add the fixture matrix, GATE-ERROR word. Check: deliberate FAIL clean; CI green.
- **S2 Measurement (F3, F4, F13)**: oc_usage.py from the v2 DB, append-spend rewrite, cost wired into runs.csv, NOWORK/REFUSED rows, effort map. Check: stub run → integer rows only.
- **S3 Watchdog (F5, F9)**: log-quiet kill, first-run timeout, 90-min cap. Check: hang stub ≤10 min; tickler stub stopped.
- **S4 Lockdown (F6)**: builder bash allowlist, gate protected paths, atomic final .result, merge checklist requirement, branch protection on main. Check: R7 refused.
- **S5 Middle tier (F1)**: EXPECT_RED mode + docs rewritten to match (or docs-only fallback if Feras prefers head-written tests). Check: R2 passes.
- **S6 Routing truth (F7, F12, F11)**: author-based reviewer, prefix from .result, Sonnet→Claude sweep. Check: grep clean; cf merge without arg; GLM run gets DeepSeek reviewer.
- **S7 handoff (F8)**: `--workflow check.yml`, 960s cap. Check: 12-min CI passes.
- **S8 Housekeeping (c, b, F14, F10)**: OC_MODEL default/probe, plugin prune + cleanup hook, neuron-priced spend + daily warning, base_red refuse.
- **S9 Proof batch (§3)** executed with full measurement, results into runs.csv and models.md. Only then claim "proven".