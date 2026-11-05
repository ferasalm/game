# Brief: row28-e-meter (agy; shell and Python, RUN_KIND=py; red tests first from the head)
You are in your own worktree on branch gemini/row28-e-meter (made from origin/main after part a). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/runs_log.py, tools/test_runs_log.py, tools/test_slots.py
Timebox: 40 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
The Dia review (11-05, verified) found the meter charging every nv-lane model one global rate of 0 (builders.conf
NV_INPUT_RATE and NV_OUTPUT_RATE), so the Cerebras hop spent prepaid credit while slots.sh said $0.00: the blind spot
behind the Cloudflare bill. Part a puts each paid OpenRouter id with its two rates in tools/free_providers.txt; the meter
must charge the model that actually ran, and runs.csv must record provider, effort, peak and cost (Feras 11-04). The
routing docs half of the old part e was done 11-05 in the Dia-review chat. Pillar served: none directly (spend safety).

## Read first
tools/free_providers.txt (its paid lines after part a), tools/slots.sh (append-spend and the monthly spend sum),
tools/nv_build.sh, tools/cross_review.sh and tools/nv_audit.sh (their append-spend calls), tools/run_state.sh
(oc_usage.py --in-rate), tools/runs_log.py, tools/builders.conf (NV_INPUT_RATE, NV_OUTPUT_RATE).

## What to build
1. tools/model_rates.py: `rates(model_id, rules_text)` returns (input, output) in USD per million tokens: a paid line's
   two rates, (0, 0) for an id a free rule allows, ValueError for an id no rule allows. CLI `python tools/model_rates.py <id>`
   prints `<input> <output>`, exit 2 with a message naming free_providers.txt for an unknown id.
2. Every spend line charges the model that ran: nv_build.sh (per model of the chain it actually ran), cross_review.sh,
   nv_audit.sh and run_state.sh pass model_rates.py's numbers; slots.sh's monthly sum adds each line's own cost instead of
   multiplying all tokens by one rate. NV_INPUT_RATE and NV_OUTPUT_RATE leave builders.conf and every script.
3. runs_log.py: runs.csv gains columns provider, effort, peak (0 or 1), cost_usd, appended after the old ones; old rows
   read back with blanks.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. tools/free_providers.txt and opencode.json (part a
owns them). Keep this prose free of backticks outside May edit.

## May edit
`tools/model_rates.py`
`tools/test_model_rates.py`
`tools/slots.sh`
`tools/test_slots.py`
`tools/nv_build.sh`
`tools/test_nv_build.py`
`tools/cross_review.sh`
`tools/nv_audit.sh`
`tools/run_state.sh`
`tools/test_run_state.py`
`tools/builders.conf`
`tools/runs_log.py`
`tools/test_runs_log.py`

## Ripple
runs.csv is read by kaizen_report.py (part b reads the peak flag) and slots.sh: keep the old column order. test_slots.py
and test_run_state.py set NV_INPUT_RATE today: they switch to a stub free_providers.txt holding one paid id. nv_build.sh
is read by every builder run: the head merges this part only when no run is live.

## Pre-mortem
- An id the rules do not cover crashes a build at its spend line (4 paid probes once crashed at theirs, LESSONS 3): the
  caller keeps its `|| true`, writes cost 0 and a WARN line naming the id in the run's log.
- A rate copied into a second place drifts: rates live only in free_providers.txt (test_model_rates reads the real file).
- Old rows break the reader: the test loads a base-era row.

## Tests
- tools/test_model_rates.py :: test_free_id_costs_zero, test_paid_id_reads_its_rates, test_unknown_id_exits_2
- tools/test_runs_log.py :: test_new_columns_round_trip, test_old_rows_read_with_blanks
- tools/test_slots.py :: test_month_sum_adds_each_lines_cost (red on the base). Player-visible: not applicable (tooling).

## Checklist
- file: tools/model_rates.py
- has: tools/runs_log.py :: peak
- test: tools/test_model_rates.py :: test_paid_id_reads_its_rates

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: Gemini 3.8 Flash (agy)`.
