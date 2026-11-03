#!/usr/bin/env bash
# Free builder lane (Feras 11-04; Cloudflare retired after an unexpected bill): runs build_pipeline.sh on opencode with
# the first NV_CHAIN model (NVIDIA NIM DeepSeek V4.1 Flash). When the provider refuses the run (rate limit, spent quota,
# 5xx: the pipeline ends NOWORK with `why: quota`), the same task reruns on the next model of the chain; a model's own
# failure (red check, no commit, a timeout) never falls through. Which work comes here: low-cost-pipeline routing.md.
# Usage (cwd = the main checkout, run_in_background): bash <this repo>/tools/nv_build.sh <task> <brief> <base> [model]
# A 4th arg pins one model and skips the chain. Keys: stored once by Feras with
# `XDG_DATA_HOME=~/.local/share/oc-v2 <OC_BIN> auth login` (Claude never handles them). Every provider is free:
# tools/free_providers.txt, test_free_providers.py.
set -euo pipefail
. "$(dirname "$0")/lib.sh"
here="$lib_dir"
task="$1"; brief="$2"; base="$3"
if [ -n "${4:-}" ]; then chain="$4"; else chain="$NV_CHAIN"; fi
dir="$(wt_dir)"

rc=0
for model in $chain; do
  rc=0
  bash "$here/build_pipeline.sh" nv "$task" "$brief" "$base" "$model" || rc=$?
  # REFUSED (exit 3) never ran a build: no token line (it appended a junk `?` row, row 26 11-02), no fallback.
  if [ "$rc" -eq 3 ]; then exit 3; fi
  bash "$here/slots.sh" append-spend "$dir/$task.log" "$task" "$NV_INPUT_RATE" "$NV_OUTPUT_RATE" "$dir/nv_spend.csv" "$dir/$task" || true
  [ "$rc" -ne 0 ] && grep -q "^why: quota" "$dir/$task.result" 2> /dev/null || break
  echo "nv_build: $model refused by its provider; next model in NV_CHAIN" >&2
done
exit $rc
