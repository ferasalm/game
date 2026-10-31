#!/bin/bash
# Plugin SessionStart hook: leaves a marker named by the session_id so .claude/hooks/session-start.sh knows studio loaded.
input="$([ -t 0 ] || timeout 2 cat 2>/dev/null)"
sid="$(printf '%s' "$input" | sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
[ -n "$sid" ] && date +%s > "${TMPDIR:-/tmp}/neon-studio-loaded-$sid"
exit 0
