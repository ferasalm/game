#!/usr/bin/env bash
# Reviews an opencode task (branch oc/<task>) the same cheap way as an agy one: report, check result, commits, stats,
# the non-test code diff and new player text. Usage: tools/oc_review.sh <task-name> [base-ref]
BRANCH_PREFIX=oc exec bash "$(dirname "$0")/agy_review.sh" "$@"
