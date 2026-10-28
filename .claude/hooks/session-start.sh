#!/bin/bash
# Session start: is THIS checkout (the session's own worktree) behind the shared branch (main)? Starts the pinned
# Godot download in the background. Output is shown to Claude. Never blocks a session (fetch is capped at 15 s).
# The hook is wired as $CLAUDE_PROJECT_DIR/... (the main checkout, which may be stale) and may start there, so it goes
# to the session's cwd from its stdin JSON (else $PWD), then runs that checkout's own copy of this script (10-28).
if [ -z "$SESSION_START_REEXEC" ]; then
  input="$([ -t 0 ] || timeout 2 cat 2>/dev/null)"
  cwd="$(printf '%s' "$input" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | sed 's#\\\\#/#g')"
  [ -n "$cwd" ] && [ -d "$cwd" ] && cd "$cwd"
fi
git rev-parse --show-toplevel > /dev/null 2>&1 || cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
cd "$(git rev-parse --show-toplevel)" || exit 0
own=".claude/hooks/session-start.sh"
if [ -z "$SESSION_START_REEXEC" ] && [ -f "$own" ] && ! cmp -s "$own" "$0"; then
  SESSION_START_REEXEC=1 exec bash "$own" < /dev/null
fi
[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] && timeout 15 git fetch -q --unshallow origin 2>/dev/null
timeout 15 git fetch -q origin main 2>/dev/null
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
behind="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
ahead="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"
echo "SYNC: $branch is $behind behind and $ahead ahead of origin/main."
[ "$behind" != "0" ] && echo "SYNC: merge origin/main before changing anything."
[ -n "$(git status --porcelain 2>/dev/null)" ] && echo "SYNC: uncommitted changes are present; look before editing."
[ -x tools/godot.sh ] && (tools/godot.sh >/dev/null 2>&1 &)
echo "Next: tell the owner the top HANDOFF.md queue row (Dept, lane, who); the cheapest worker that does it well does it"
echo "(docs/WORKFLOW.md, Start here step 3); bash tools/status.sh shows the state."
exit 0
