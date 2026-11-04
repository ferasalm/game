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

# Preflight (row 28 part d, Feras 11-04): builds log in to opencode's oc-v2 data dir (lib.sh oc_run), so a chain model
# whose provider is not stored there fails at its first call with an error NV_FALLBACK_RE does not know. Ask
# `auth list` once (first column = provider, case-insensitive; opencode itself needs no login) and skip such models.
# A failing or unparseable `auth list` never blocks: warn and run the chain unchanged.
if [ "${OC_MAJOR:-2}" = 1 ]; then auth_dir="$HOME/.local/share/oc-cli"; auth_flag=""; else auth_dir="$HOME/.local/share/oc-v2"; auth_flag="--standalone"; fi
logged=""
if auth_out="$(XDG_DATA_HOME="$auth_dir" timeout 60 "${OC_BIN:-opencode}" auth list $auth_flag < /dev/null 2> /dev/null)"; then
  logged="$(printf '%s\n' "$auth_out" | tr -d '\r' | awk '$1 ~ /^[A-Za-z][A-Za-z0-9_-]*$/ {print tolower($1)}')"
fi
if [ -z "$logged" ]; then
  echo "nv_build: warning: 'auth list' gave no providers; running the chain unchanged" >&2
else
  usable=""
  login_hint='$env:XDG_DATA_HOME="$HOME\.local\share\oc-v2"; & '"${OC_BIN:-opencode}"' auth login --standalone'
  for model in $chain; do
    prov="${model%%/*}"
    if [ "$prov" = opencode ] || printf '%s\n' "$logged" | grep -qx "$(printf '%s' "$prov" | tr 'A-Z' 'a-z')"; then
      usable="$usable $model"
    else
      echo "nv_build: skipping $model: ${prov^} is not logged in to oc-v2 (PowerShell: $login_hint)" >&2
    fi
  done
  # nothing left to run (every model skipped, or the pinned one): REFUSED; the skip lines above name the missing logins
  if [ -z "$usable" ]; then exit 3; fi
  chain="$usable"
fi

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
