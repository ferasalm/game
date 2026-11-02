# Brief: row26-s4-tests (SCOPE RUN: GLM-5.3 max writes ONLY the red tests; RUN_KIND=py)
You are in your own worktree on branch oc/row26-s4-tests (made from origin/worktree-row26-pipeline-v2; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/test_cross_review_sh.py, tools/test_handoff.py
Timebox: 40 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: tools/cross_review.sh, merge_run.sh, handoff.sh and builders.conf will be changed by docs/briefs/row26-s4-routing.md (read it fully: its "What to build" items 1-5 are the spec). This run writes ONLY the failing tests for that spec. A different model implements them next and cannot edit them. Weak tests are the usual defect: assert exact outputs (which `--model` the stub opencode received, which exit code), never "ran without error".

## Read first
docs/briefs/row26-s4-routing.md, tools/cross_review.sh, tools/merge_run.sh, tools/handoff.sh, tools/builders.conf, tools/test_cross_review_sh.py (import its helpers `toy` and `review`; the stub logs `ARGS` lines you can assert on), tools/test_handoff.py (its stubbing of HANDOFF_CI and the git remote).

## What to build
ONE new file `tools/test_routing.py` (<= 200 lines, functions <= 40 lines), plain `test_*` functions, ending with the `run_cases` block used by tools/test_runs_log.py. Stubs only (no network, no real gh, no real opencode). One test per rule:
1. `test_a_deepseek_run_is_reviewed_by_glm`: a `<wt_dir>/job.result` with `builder cf` and `model cloudflare-workers-ai/deepseek-v4.1-flash-high`; cross_review.sh with no reviewer argument -> the stub opencode's ARGS contain `--model cloudflare-workers-ai/@cf/zai-org/glm-5.3`.
2. `test_a_glm_run_is_reviewed_by_deepseek_max`: `model cloudflare-workers-ai/@cf/zai-org/glm-5.3` -> ARGS contain the CF_MODEL value (`@cf/deepseek-ai/deepseek-v4.1-flash-1017`).
3. `test_an_agy_run_is_reviewed_by_glm`: `builder agy` -> glm model.
4. `test_unknown_family_falls_back_to_the_branch_prefix_rule`: no `.result` and branch oc/job -> agy reviewer as today (the stub agy is called).
5. `test_an_explicit_reviewer_argument_wins`: `.result` says deepseek, 5th argument `agy` -> agy stub called, no opencode call.
6. `test_the_reviewer_models_are_data_in_builders_conf`: XR_REVIEWER_DEEPSEEK=cloudflare-workers-ai/@cf/other/model in the environment -> that model in ARGS.
7. `test_merge_run_reads_the_prefix_from_the_result`: a toy repo with branch `oc/job`, a `.result` starting `PASS 10:00 oc/job` with a `VERDICT PASS` line and `checked <sha>`; `merge_run.sh job` (no prefix) merges it; same for `gemini/`.
8. `test_merge_run_refuses_a_result_without_a_verdict_line`: first word PASS, no `VERDICT PASS` line -> exit 1, message names the `.result`, nothing merged.
9. `test_ci_state_words`: tools/ci_state.py on JSON: `[]` -> empty line; one queued + one success -> `in_progress`; all success -> `success`; one failure -> `failure`; a cancelled run -> `failure`.
10. `test_handoff_ci_asks_for_the_check_workflow`: a fake `gh` first on PATH records its args and prints a one-run success JSON; a --main handoff in test_handoff's toy -> the recorded args contain `--workflow check.yml` and the commit sha, and the run passes.
11. `test_ci_wait_cap_is_960_and_overridable`: builders.conf defines CI_WAIT_SEC 960; a stub that stays `in_progress` with CI_WAIT_SEC=1 fails handoff with `fail ci` quickly (sleep stubbed or WATCH-style env if handoff.sh has one; else assert the cap value in the file text).
12. `test_oc_model_defaults_to_the_cf_model`: `bash -c ". tools/lib.sh; echo $OC_MODEL $CF_MODEL"` prints two equal words.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit. Write NO product code: not the shell tools, not builders.conf, not ci_state.py.

## May edit
none

## Ripple
none: tests only. They are red on the base because the spec is unbuilt; do not run check.sh to turn them green.

## Pre-mortem
- A test passes on the base (proves nothing): run `python tools/test_routing.py` once and confirm each fails for the stated reason before committing.
- A toy repo on Windows: LESSONS 4 (newline="\n", no doubled backslashes); copy the style of the imported helpers.
- A test touches the real GitHub: a fake gh on PATH only.

## Tests
- tools/test_routing.py :: every test (red on the base)

## Checklist
- file: tools/test_routing.py

## Proof
Print the last 15 lines of `python tools/test_routing.py` (expect FAIL lines); final message ends with `Built-by: GLM-5.3 max (opencode)`.
