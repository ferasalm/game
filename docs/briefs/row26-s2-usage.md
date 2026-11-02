# Brief: row26-s2-usage (cf DeepSeek high; Python only, RUN_KIND=py)
You are in your own worktree on branch oc/row26-s2-usage (made from origin/worktree-row26-pipeline-v2; the base is pushed). Follow GEMINI.md, including
<review_misses>. Load the builders skill.
Pattern: tools/slots.sh, tools/runs_log.py
Timebox: 40 min (<= 45). First commit within 15 min, then small WIP commits.

## Why
Feras 11-02: the low-cost pipeline's cost was never measured (docs/runs.csv says cost 0, cf_spend.csv says `?`). Probed 11-02: opencode's log holds no token counts, but `opencode session export --standalone <id>` prints per-session JSON with `info.tokens` {input, output, reasoning, cache {read, write}}. Unknown must read `?`, never 0. Pillar served: none directly (keeps the build system honest).

## Read first
tools/test_oc_usage.py, tools/test_runs_log.py (the red tests, read-only: they define every contract), tools/runs_log.py (extend it), tools/builders.conf (OC_BIN, OC_MAJOR), opencode.json (model keys and `reasoning_effort`).

## What to build
1. `tools/oc_usage.py` (<= 120 lines, functions <= 40 lines), subcommands:
   - `sum FILE...`: read export JSONs, print ONE json line {sessions, input, output, reasoning, cache_read, cache_write} summed from each file's `info.tokens`; no files -> sessions 0.
   - `fields --in-rate R --out-rate R`: read that json line on stdin, print `in,out,usd`; out = output + reasoning; usd = (in*in_rate + out*out_rate)/1e6 rounded to 4 decimals with trailing zeros dropped but two decimals kept (0.66, 0.0123, 0.00). sessions 0 -> `?,?,?`.
   - `collect --wt DIR`: run through `bash -c` with cwd DIR and XDG_DATA_HOME=$HOME/.local/share/oc-v2: `"$OC_BIN" session list --standalone` (OC_MAJOR=1: XDG_DATA_HOME=$HOME/.local/share/oc-cli and no `--standalone`), take the first tab-separated column of each line that starts `ses_`, run `"$OC_BIN" session export [--standalone] <id>` for each, then do what `sum` does. Any failure, empty list or bad JSON -> sessions 0 and exit 0 (a broken meter must never fail a run). Timeout 60 s per call. OC_BIN defaults to `$HOME/.local/opt/opencode-2.2.2/opencode.exe`, OC_MAJOR to 2.
2. `tools/model_effort.py MODEL`: print none|low|medium|high|max or `-`. Strip a leading `cloudflare-workers-ai/` and look the rest up under provider cloudflare-workers-ai in opencode.json (repo root, found relative to this file); use that model's `options.reasoning_effort`. Not found: take the last of none|low|medium|high|max found in the name (`-fast` means none); else `-`.
3. `tools/runs_log.py`: HEADER gains tokens_in, tokens_out, usd_est, cost_source, idle_min (in that order, after real_findings); `append` gets optional --tokens-in, --tokens-out, --usd, --source, --idle-min (defaults `?`, `?`, `?`, `unknown`, `?`); keep --cost and --findings accepted. An existing file with the old 9-column header is rewritten once: new header, old rows padded `?,?,?,unknown,?`. Allowed gate words are free text (ERROR and REFUSED must log). Keep `newline="\n"`.

## Do NOT edit
D6 defaults, protected by tools/build_gate.py without being listed. Keep this prose free of backticks outside May edit.
`tools/build_pipeline.sh`
`tools/slots.sh`
`tools/cf_build.sh`
`opencode.json`

## May edit
`tools/runs_log.py`

## Ripple
tools/build_pipeline.sh calls runs_log.py append with the old arguments: they stay valid (new ones optional). Wiring the new tools into the pipeline is a later brief. docs/runs.csv is migrated by the first append, not here. docs/MAP.md refreshes itself (map.py).

## Pre-mortem
- A real export has more fields than the fixture: read only info.tokens with .get defaults.
- Windows paths and quoting in bash -c: pass DIR and OC_BIN as positional parameters, never interpolate them into the script text.
- A second migration corrupting the file: migrate only when the first line equals the old header exactly.

## Tests
- tools/test_oc_usage.py :: every test (red on the base: the scripts do not exist)
- tools/test_runs_log.py :: every test (red on the base: the new columns do not exist)

## Checklist
- file: tools/oc_usage.py
- file: tools/model_effort.py
- has: tools/oc_usage.py :: main
- test: tools/test_oc_usage.py :: test_collect_lists_a_worktrees_sessions_and_sums_their_exports
- test: tools/test_runs_log.py :: test_an_old_nine_column_file_is_migrated_and_old_rows_read_unknown

## Proof
`bash tools/check.sh --no-godot` raw last 15 lines; final message ends with `Built-by: DeepSeek V4.1 Flash high (opencode)`.
