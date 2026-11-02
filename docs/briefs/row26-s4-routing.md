# Brief: row26-s4-routing (cf DeepSeek high; shell and Python, RUN_KIND=py)
You are in your own worktree on branch oc/row26-s4-routing (made from origin/worktree-row26-pipeline-v2; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/cross_review.sh, tools/test_cross_review_sh.py
Timebox: 45 min. First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: three routing contradictions. (1) The skill says GLM max reviews DeepSeek and agy work and DeepSeek reviews GLM work, but cross_review.sh picks the reviewer from the branch prefix and always uses DeepSeek max. (2) merge_run.sh defaults to the gemini prefix, so every cf run needs a hand-typed `oc`, and it merges on any `.result` whose first word is PASS. (3) handoff.sh waits for "the first workflow run" for a commit and gives up after 600 s while CI may take 15 min; a second workflow (the Android export, D17) would make "first" the wrong one. Also OC_MODEL points at a spent free route. Pillar served: none directly.

## Read first
tools/cross_review.sh, tools/merge_run.sh, tools/handoff.sh lines 60-90, tools/builders.conf, tools/test_routing.py (the red tests: read-only), tools/test_cross_review_sh.py and tools/test_handoff.py (they must stay green untouched).

## What to build
1. tools/builders.conf: define CF_MODEL first, then `OC_MODEL` defaults to `$CF_MODEL`; new knobs `XR_REVIEWER_GEMINI`, `XR_REVIEWER_DEEPSEEK` (both default `cloudflare-workers-ai/@cf/zai-org/glm-5.3`) and `XR_REVIEWER_GLM` (default `$CF_MODEL`); `CI_WAIT_SEC` default 960.
2. tools/cross_review.sh: with no 5th argument, read `$(wt_dir)/<run>.result`: family is `gemini` when its `builder` line is agy, else `glm` when its `model` line contains `glm`, `deepseek` when it contains `deepseek`. A known family picks reviewer cf with that family's XR_REVIEWER_* model. No `.result`, no `model` line or an unknown family: the old branch-prefix rule. An explicit 5th argument always wins. The cf spend line passes the review box as append-spend's 7th argument (WT) so tokens come from the box's session.
3. tools/merge_run.sh: with no 2nd argument the prefix is the part before `/` in the `.result` first line's 3rd field (`PASS 19:56 oc/row25` -> oc); an explicit argument still wins. Refuse (exit 1, message names the file) unless the `.result` contains a line that is exactly `VERDICT PASS`.
4. New tools/ci_state.py (<= 50 lines): reads the JSON of `gh run list --json status,conclusion` on stdin and prints ONE word: empty list -> nothing (empty line); any run whose status is not `completed` -> `in_progress`; every run `success` -> `success`; otherwise `failure`.
5. tools/handoff.sh: the default ci_cmd (HANDOFF_CI still overrides) becomes `gh run list --workflow check.yml --commit <sha> --json status,conclusion | python tools/ci_state.py` (use `$py` if handoff.sh has it); the wait cap is CI_WAIT_SEC instead of 600.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`tools/test_cross_review_sh.py`
`tools/test_handoff.py`
`tools/build_pipeline.sh`
`tools/slots.sh`

## May edit
`tools/cross_review.sh`
`tools/merge_run.sh`
`tools/handoff.sh`
`tools/builders.conf`

## Ripple
merge_run.sh is called by name from the builders skill, the pm plugin handoff skill and docs: the new default only removes a required argument. cross_review.sh keeps its usage line. build_pipeline.sh (another brief) writes the `model` line this reads; a missing line falls back to the old rule. handoff.sh keeps HANDOFF_CI so test_handoff.py stays green. docs/MAP.md refreshes itself (map.py).

## Pre-mortem
- A reviewer of the author's own family reviews its own work: the map is data in builders.conf and the red test pins author -> reviewer for all three families.
- CI shows two runs for one commit (push plus pull_request): ci_state.py waits for every run of the workflow and fails if any failed.
- merge_run.sh fed an old `.result` without VERDICT: it refuses and says so; the pipeline always writes the line.

## Tests
- tools/test_routing.py :: every test (red on the base)

## Checklist
- file: tools/ci_state.py
- test: tools/test_routing.py :: test_merge_run_reads_the_prefix_from_the_result

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash high (opencode)`.
