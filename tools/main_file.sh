#!/usr/bin/env bash
# Prints a file as it is on origin/main, after a fetch, without touching the work tree (row 23 d, 2026-11-01).
# A read-only review reads this instead of a possibly stale checkout (LESSONS: the 9-commits-behind review).
# Usage: bash tools/main_file.sh <path>   (test: tools/test_git_helpers.py)
set -uo pipefail
[ $# -eq 1 ] || { echo "Usage: bash tools/main_file.sh <path>" >&2; exit 2; }
git fetch -q origin main || { echo "main_file: fetch failed" >&2; exit 1; }
git show "origin/main:$1"
