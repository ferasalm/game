# Claude's own critique (written BEFORE reading the GLM and DeepSeek critiques)

## Verified facts (probed this session)
- `opencode session export --standalone <sid>` (cwd = the run's worktree, XDG_DATA_HOME=oc-v2) returns JSON with
  info.tokens{input,output,reasoning,cache{read,write}}, info.cost (opencode's own price table: not Cloudflare's),
  info.outcome, info.time{busy,idle}. `session list --standalone` lists the sessions of that worktree. The default log
  (.log) has no tokens; `--format json` stream has no step_finish/tokens in v2. => cost is measurable after the run.
- Gate crash (row25-sync-dirty): build_gate.py got FileNotFoundError on the brief path 30 min after launch; build_pipeline
  turns any gate output without a VERDICT line into "FAIL" (status="${status:-FAIL}"), so a crash looks like a real fail.
- 25 idle minutes: the only exit after a builder's last commit is IDLE_MIN (no commit for 25 min). Builder process
  lingers after its final answer (session idle, process alive).
- kaizen: 8 entries in installed_plugins.json (1 project + 7 local, 5 of them for worktrees; 3 of those paths no longer
  exist / are other chats' worktrees); all disabled. Harmless but noisy; a hand edit of a user-global file.

## Findings (mine)
1 [high] The skill describes a 3-tier flow no tool implements: no "scope + red tests only" stage, no test lock, reviewer
  chosen by branch prefix (gemini/ -> cf, oc/ -> agy) not by author model, merge_run needs the prefix argument. It is
  prose the head must hand-run; every hand-run is a place to deviate. Fix: three thin stage scripts or flags
  (scope, build, xr) around existing tools + a `pipeline.sh status`; a `.pipeline` run record file per task.
2 [high] Cost: runs.csv cost/findings are literals 0 (build_pipeline.sh:173); cf_spend.csv `?`. Unknown is recorded as
  zero. Fix: tools/oc_usage.py reads `session export` per session of the worktree; runs.csv gets tokens_in, tokens_out,
  usd_est columns; unknown = `?` never 0; test with a fixture export JSON.
3 [high] Idle: add a post-commit quiet watchdog (log not growing for QUIET_SEC and >=1 commit -> kill, check, gate) plus
  idle_minutes column. Keep IDLE_MIN for a no-commit builder. Test with the stub builder that commits then sleeps.
4 [high] Gate crash reads as FAIL. Fix: ERROR word + reason; copy the brief to game-wt/<task>.brief.md at launch and use
  that copy (cause: brief read from a mutable path 30 min later).
5 [med] Proof is thin: P1 godot run (cf high), P2 agy py run, P3 agy godot run, P4 locked-red-test flow with GLM scoping,
  P5 deliberate gate failures (edit protected test, edit forbidden file, no commit, gate crash), P6 cross-review with
  author-different reviewer. Measure tokens, minutes, idle minutes, fix passes, flags confirmed/false.
6 [med] Sonnet -> Claude: replace only where the head role is meant (skill, builders skill Sonnet bullet, CLAUDE.md lean
  process, queue Who column "Sonnet high"); keep "never spawn a Sonnet subagent" and logged history untouched (it is a
  ban on a model, and decisions-log/archives are dated records).
7 [med] CI wait (handoff.sh:69): `--commit SHA --limit 1` is correct today with one workflow, but (a) a push + a
  pull_request run on the same commit give two runs, the newest can be the other; (b) the planned Android export
  workflow (D17) will make "the first run" the wrong workflow. Fix: pin `--workflow check.yml`, require all runs of the
  SHA to be success. Test through the HANDOFF_CI stub with a two-run fixture.
8 [med] OC_MODEL default is a spent free route and `build_pipeline.sh oc` silently uses it. Fix: default OC_MODEL to the
  CF model, and refuse `opencode/*-free` builders without OC_ALLOW_FREE=1; HANDOFF key line corrected.
9 [low] runs.csv effort parsed from the model name by regex: `-1017` max shows "-". Read reasoning_effort from
  opencode.json by model key.
10 [low] merge_run default prefix gemini: derive the prefix from the .result `builder` line.
11 [low] skill vs builders skill contradictions: "Max 3 fix rounds" vs FIX_PASSES=2; "first commit within 15 minutes" vs
  IDLE_MIN 25; CF billed in neurons but spend in USD per M tokens.
12 [low] kaizen duplicates: prune entries whose projectPath no longer exists after a backup; needs Feras's OK (user-global).
