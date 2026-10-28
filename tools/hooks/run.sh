#!/bin/bash
# Runs tools/hooks/<name>.py for a Claude hook. settings.json wires hooks as $CLAUDE_PROJECT_DIR/..., the main checkout,
# which lags until tools/sync_main.sh pulls it (LESSONS 4): this runs the session's own copy (cwd from the hook's stdin
# JSON), else this checkout's. A missing script exits 0: `python <missing file>` exits 2, which blocks a PreToolUse tool.
# --required (a money or safety gate, e.g. pre_spend): a missing script BLOCKS (exit 2) instead: fail closed.
# Usage (settings.json): bash "$CLAUDE_PROJECT_DIR/tools/hooks/run.sh" <name> [--required]   (test: tools/test_hook_run.py)
name="$1"
input="$([ -t 0 ] || timeout 5 cat 2>/dev/null)"
cwd="$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's#\\\\#/#g')"
script=""
if [ -n "$cwd" ] && [ -d "$cwd" ]; then
  own="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)/tools/hooks/$name.py"
  [ -f "$own" ] && script="$own"
fi
[ -z "$script" ] && [ -f "$(dirname "$0")/$name.py" ] && script="$(dirname "$0")/$name.py"
if [ -z "$script" ]; then
  [ "$2" = "--required" ] && { echo "BLOCKED: required hook tools/hooks/$name.py not found" >&2; exit 2; }
  exit 0
fi
printf '%s' "$input" | python "$script"
