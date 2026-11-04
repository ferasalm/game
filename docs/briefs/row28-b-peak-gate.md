# Brief: row28-b-peak-gate (nv or agy; Python, RUN_KIND=py)
You are in your own worktree on branch oc/row28-b-peak-gate (made from origin/main after part a). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/free_mb.py, tools/kill_tree.py
Timebox: 30 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-04 (decision: route around peak on OpenRouter; any DeepSeek call NOT through OpenRouter uses a gate). DeepSeek's own API charges double Monday to Friday 01:00-04:00 and 06:00-10:00 UTC (04:00-07:00 and 09:00-13:00 GMT+3; its pricing page, 11-04), except Chinese public holidays. Pillar served: none directly (spend control).

## Read first
tools/builders.conf, tools/lib.sh (how a model slug reaches a run), tools/kaizen_report.py and its test.

## What to build
1. `tools/peak_gate.py` (<= 90 lines): `peak_gate.py <model-slug> [--now ISO8601Z]`. Exit 0 = go. Exit 1 = peak: print `peak: <slug> costs 2x until HH:MM GMT+3; wait or use openrouter/`.
2. A slug is gated only when it names DeepSeek and does NOT start with openrouter/ and not nvidia/ or opencode/ free routes (those cost 0). Anything else exits 0.
3. Peak windows come from builders.conf (PEAK_UTC="01:00-04:00 06:00-10:00", PEAK_DAYS="Mon Tue Wed Thu Fri"), plus a holidays file tools/cn_holidays.txt (one ISO date per line, 2026 public holidays, source URL in its first comment line).
4. build_pipeline.sh calls the gate before the build for the model it runs; a refusal is REFUSED (exit 3).
5. kaizen_report.py shows spend split peak and off-peak for paid DeepSeek rows (runs.csv gains the peak flag in part e).

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.

## May edit
`tools/peak_gate.py`
`tools/cn_holidays.txt`
`tools/builders.conf`
`tools/build_pipeline.sh`
`tools/kaizen_report.py`

## Locked tests and interface (the head wrote tools/test_peak_gate.py; read it first, do not edit it)
- builders.conf: add `: "${PEAK_UTC:=01:00-04:00 06:00-10:00}"` and `: "${PEAK_DAYS:=Mon Tue Wed Thu Fri}"`. peak_gate.py reads an env var of the same name first, else parses builders.conf. Window start inclusive, end exclusive, clock and weekday are UTC. The message end time is the window end plus 3 hours (04:00 UTC prints 07:00 GMT+3).
- Holidays: env PEAK_HOLIDAYS (a path) else tools/cn_holidays.txt. Line 1 is a comment with a URL and the year; later lines are ISO dates or comments. When the year of the checked day differs from the year on line 1, print a line starting WARN naming that year on stderr and still decide by the windows.
- A slug is gated only when it contains deepseek (any case) and does not start with openrouter/, nvidia/ or opencode/. Anything else exits 0 with no output.
- build_pipeline.sh: before the build, run the gate for the run's model (model_used) with `--now "$PEAK_NOW"` when PEAK_NOW is set (tests); exit 1 means refuse "$output" (exit 3, no .result), the existing refuse function does this.
- kaizen_report.py: when the csv has a peak column, add after the group lines one line `peak split  peak usd A (N runs)  off-peak usd B (M runs)` (usd_est summed, two decimals; peak 1 = peak, 0 = off-peak; ? or empty counts in neither). No peak column or no 0/1 rows: no line. Old tests keep passing.
- tools/cn_holidays.txt content, from the head's memory and UNVERIFIED (line 1 must say so; Feras or a Claude checks the State Council notice before relying on it): 2026-01-01 to 2026-01-03, 2026-02-15 to 2026-02-23, 2026-04-04 to 2026-04-06, 2026-05-01 to 2026-05-05, 2026-06-19 to 2026-06-21, 2026-09-25 to 2026-09-27, 2026-10-01 to 2026-10-07, one ISO date per line. Line 1 example: `# 2026 mainland China public holidays, UNVERIFIED draft from memory; check https://www.gov.cn (State Council holiday notice)`.

## Ripple
build_pipeline.sh is read by every run: edit only while no run is live (LESSONS 10-30). kaizen_report has a test (test_kaizen_report.py): add cases, keep the old.

## Pre-mortem
- The gate blocks free NIM DeepSeek: the slug rule above plus a test per prefix.
- Clock or timezone mistakes: the test fixes now with --now at both window edges, a Saturday, and a holiday.
- Holiday list goes stale: the file's first line names its source and year; the gate warns when the year differs.

## Tests
- tools/test_peak_gate.py :: edges of both windows, weekend, holiday, openrouter route, nvidia route (red on the base). Player-visible: not applicable.

## Checklist
- file: tools/peak_gate.py
- has: tools/peak_gate.py :: main
- test: tools/test_peak_gate.py :: test_peak_window_edges

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: <model> (opencode)`.
