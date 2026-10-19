#!/bin/bash
# Session start: is this branch behind the shared branch (main)? Starts the pinned Godot download in the
# background. Output is shown to Claude. Never blocks a session.
cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}" || exit 0
[ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ] && git fetch -q --unshallow origin 2>/dev/null
git fetch -q origin main 2>/dev/null
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
behind="$(git rev-list --count HEAD..origin/main 2>/dev/null || echo '?')"
ahead="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo '?')"
echo "SYNC: $branch is $behind behind and $ahead ahead of origin/main."
[ "$behind" != "0" ] && echo "SYNC: merge origin/main before changing anything."
[ -n "$(git status --porcelain 2>/dev/null)" ] && echo "SYNC: uncommitted changes are present; look before editing."
(tools/godot.sh >/dev/null 2>&1 &)
echo "Next: tell the owner the next step and its model and effort (HANDOFF.md, Next steps)."
exit 0
