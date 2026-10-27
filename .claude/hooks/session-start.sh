#!/bin/bash
# Session start: is THIS checkout (the session's own worktree, $PWD) behind the shared branch (main)? Starts the pinned
# Godot download in the background. Output is shown to Claude. Never blocks a session (fetch is capped at 15 s).
git rev-parse --show-toplevel > /dev/null 2>&1 || cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
cd "$(git rev-parse --show-toplevel)" || exit 0
[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] && timeout 15 git fetch -q --unshallow origin 2>/dev/null
timeout 15 git fetch -q origin main 2>/dev/null
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
behind="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
ahead="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"
echo "SYNC: $branch is $behind behind and $ahead ahead of origin/main."
[ "$behind" != "0" ] && echo "SYNC: merge origin/main before changing anything."
[ -n "$(git status --porcelain 2>/dev/null)" ] && echo "SYNC: uncommitted changes are present; look before editing."
[ -x tools/godot.sh ] && (tools/godot.sh >/dev/null 2>&1 &)
echo "Next: tell the owner the top HANDOFF.md queue row for this chat (lane, who); bash tools/status.sh shows the state."
exit 0
