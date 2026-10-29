#!/usr/bin/env bash
# Paid fallback builder (DECISIONS 2026-10-23: Cloudflare Workers AI DeepSeek V4.1 Flash, Workers Paid, no $ cap since 10-30, spend in cf_spend.csv): runs
# build_pipeline.sh on opencode with that model. Use only when agy and Inkling :free are out of quota.
# Usage (cwd = the main checkout, run_in_background): bash <this repo>/tools/cf_build.sh <task> <brief> <base> [model]
# Needs (Feras sets them once; Claude never handles the token): the user env var CLOUDFLARE_ACCOUNT_ID (setx) and the
# key from `XDG_DATA_HOME=~/.local/share/oc-cli opencode auth login` -> Cloudflare Workers AI. Spend: Cloudflare
# dashboard -> AI -> Workers AI (10,000 free neurons a day, then $0.011 per 1,000).
set -euo pipefail
. "$(dirname "$0")/lib.sh"
here="$lib_dir"
task="$1"; brief="$2"; base="$3"
model="${4:-$CF_MODEL}"  # 4th arg: another Workers AI model (e.g. kimi-k2.7-code)
if [ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]; then  # a setx value is not in shells started before it was set
  CLOUDFLARE_ACCOUNT_ID="$(powershell -NoProfile -Command \
    "[Environment]::GetEnvironmentVariable('CLOUDFLARE_ACCOUNT_ID','User')" | tr -d '\r')"
fi
[ -n "$CLOUDFLARE_ACCOUNT_ID" ] || { echo "CLOUDFLARE_ACCOUNT_ID is not set (Feras: setx CLOUDFLARE_ACCOUNT_ID <id>)" >&2; exit 1; }
export CLOUDFLARE_ACCOUNT_ID

rc=0
bash "$here/build_pipeline.sh" cf "$task" "$brief" "$base" "$model" || rc=$?

dir="$(wt_dir)"
log="$dir/$task.log"
spend_csv="$dir/cf_spend.csv"
bash "$here/slots.sh" append-spend "$log" "$task" "$CF_INPUT_RATE" "$CF_OUTPUT_RATE" "$spend_csv"
exit $rc
