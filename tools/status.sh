#!/usr/bin/env bash
# One look at the state of the work (Feras 2026-10-27): builders, branches not yet on main, worktrees with nothing left,
# the main checkout, the HANDOFF queue and what waits on Feras. Read-only; reads HANDOFF.md from origin/main.
# Usage: bash tools/status.sh   (STATUS_DAYS=7: unmerged branches older than this are only counted)
set -uo pipefail
. "$(dirname "$0")/lib.sh"
main="$(main_root)"; days="${STATUS_DAYS:-7}"; now=$(date +%s)
tip=origin/main; git -C "$main" rev-parse -q --verify "$tip" > /dev/null || tip=main

echo "== Builders"
bash "$(dirname "$0")/slots.sh" | sed 's/^/  /'

declare -A wt_of; detached=()  # finished session worktrees are often detached: no branch name to find them by
while read -r key val; do
  case "$key" in
    worktree) path="$val" ;; HEAD) head="$val" ;;
    branch) wt_of["${val#refs/heads/}"]="$path" ;; detached) detached+=("$path|$head") ;;
  esac
done < <(git -C "$main" worktree list --porcelain)

echo "== Not on main yet (commits in the last $days days)"
old=0; idle_wt=()
while IFS='|' read -r br ts rel; do
  [ "$br" = main ] && continue
  ahead=$(git -C "$main" rev-list --count "$tip..$br" 2> /dev/null || echo 0)
  wt="${wt_of[$br]:-}"
  if [ "$ahead" -eq 0 ]; then [ -n "$wt" ] && idle_wt+=("$wt"); continue; fi
  if [ $((now - ts)) -gt $((days * 86400)) ]; then old=$((old + 1)); continue; fi
  dirty=""; [ -n "$wt" ] && [ -n "$(git -C "$wt" status --porcelain 2> /dev/null | head -n 1)" ] && dirty=", uncommitted changes"
  echo "  $br: $ahead commits, last $rel${wt:+, worktree $(basename "$wt")}$dirty"
done < <(git -C "$main" for-each-ref --sort=-committerdate refs/heads --format='%(refname:short)|%(committerdate:unix)|%(committerdate:relative)')
for d in "${detached[@]}"; do
  wt="${d%|*}"; ahead=$(git -C "$main" rev-list --count "$tip..${d#*|}" 2> /dev/null || echo 0)
  if [ "$ahead" -eq 0 ]; then idle_wt+=("$wt"); else echo "  (detached) $(basename "$wt"): $ahead commits"; fi
done
[ $old -gt 0 ] && echo "  + $old older unmerged branches: git branch --no-merged $tip"

echo "== Worktrees with nothing beyond main (finished or not started; finished: archive the session)"
for wt in "${idle_wt[@]}"; do
  dirty=""; [ -n "$(git -C "$wt" status --porcelain 2> /dev/null | head -n 1)" ] && dirty=" (uncommitted changes)"
  echo "  $(basename "$wt")$dirty"
done
[ ${#idle_wt[@]} -eq 0 ] && echo "  (none)"

n=$(git -C "$main" status --porcelain | wc -l)
echo "== Main checkout: $n uncommitted or untracked paths"
git -C "$main" status --porcelain | head -n 5 | sed 's/^/  /'

rows() {  # <section heading regex>: the data rows of the first table under that "## " heading in HANDOFF.md
  git -C "$main" show "$tip:HANDOFF.md" 2> /dev/null |
    awk -v h="$1" '/^## /{on = ($0 ~ h)} on && /^\|/ && !/^\|[-: |]+\|$/' | tail -n +2
}
echo "== Queue (HANDOFF.md on $tip, next 3 not done)"
q="$(rows '^## Queue' | grep -v -i '| *done *|' | head -n 3)"
echo "${q:-  (no Queue table in HANDOFF.md)}" | sed 's/^|/  |/'
echo "== Open points"
w="$(rows '^## Open points')"
echo "${w:-  (none)}" | sed 's/^|/  |/'
