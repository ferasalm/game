#!/usr/bin/env bash
# Fetch a web page with the Obscura headless browser (Feras 10-28/11-03: instead of Chrome for builders and research).
# Usage: bash tools/obscura.sh <http(s)-url> [text|markdown|html|links|assets] (default text); output on stdout.
# The binary: $OBSCURA_BIN, else <main checkout>/Obscura/obscura.exe (git-ignored; Feras put it there). Never --stealth
# (his rule: no fingerprint spoofing); loopback and private addresses stay blocked (Obscura's default). OBSCURA_TIMEOUT
# seconds (default 60) kills the whole process tree. Exit: 0 ok, 2 usage, 3 not installed, 124 timeout, else Obscura's own.
set -uo pipefail
. "$(dirname "$0")/lib.sh"
url="${1:-}"; mode="${2:-text}"
case " $* " in *stealth*) echo "obscura.sh: --stealth is not allowed (Feras's rule)" >&2; exit 2 ;; esac
case "$url" in http://*|https://*) ;; *) echo "usage: obscura.sh <http(s)-url> [text|markdown|html|links|assets]" >&2; exit 2 ;; esac
case "$mode" in text|markdown|html|links|assets) ;; *) echo "obscura.sh: mode must be text, markdown, html, links or assets (not $mode)" >&2; exit 2 ;; esac
bin="${OBSCURA_BIN:-$(main_root)/Obscura/obscura.exe}"
[ -x "$bin" ] || { echo "obscura.sh: no Obscura at $bin (put obscura.exe in <checkout>/Obscura/ or set OBSCURA_BIN)" >&2; exit 3; }
run_limited "${OBSCURA_TIMEOUT:-60}" "$bin" fetch "$url" --dump "$mode" < /dev/null
