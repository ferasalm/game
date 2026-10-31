#!/usr/bin/env bash
# Fetches and fast-forwards the current branch to origin/<branch> (default: the current branch; "main" for a branch that
# only follows main), so a chat starts on the latest base in one call (row 23 d, 2026-11-01).
# Prints MERGE_BASE PASS <short sha> or MERGE_BASE FAIL <reason>; never creates a merge commit.
# Usage: bash tools/merge_base.sh [branch]   (test: tools/test_git_helpers.py)
set -uo pipefail
branch="${1:-$(git rev-parse --abbrev-ref HEAD)}"
git fetch -q origin "$branch" || { echo "MERGE_BASE FAIL fetch origin/$branch"; exit 1; }
if ! git merge -q --ff-only "origin/$branch"; then
  echo "MERGE_BASE FAIL not a fast-forward: merge origin/$branch by hand"
  exit 1
fi
echo "MERGE_BASE PASS $(git rev-parse --short HEAD)"
