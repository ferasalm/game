#!/usr/bin/env bash
# Test-run slots shared by every worktree on this machine: at most CHECK_SLOTS Godot test suites at once. Four at once
# filled 32 GB (2026-10-23: "Parameter mem is null", exit 139/127 = false FAILs). Sourced by tools/check.sh.
CHECK_SLOTS="${CHECK_SLOTS:-2}"; CHECK_SLOT_STALE_MIN=20
check_slot_dir="${CHECK_SLOT_DIR:-${TEMP:-/tmp}/qarnaw-check-slots}"; check_slot=""

acquire_check_slot() {  # waits until a slot is free; a slot older than CHECK_SLOT_STALE_MIN minutes counts as dead
  mkdir -p "$check_slot_dir"; local waited=0
  while :; do
    find "$check_slot_dir" -mindepth 1 -maxdepth 1 -type d -mmin +"$CHECK_SLOT_STALE_MIN" -exec rm -rf {} + 2> /dev/null
    for i in $(seq 1 "$CHECK_SLOTS"); do
      if mkdir "$check_slot_dir/slot$i" 2> /dev/null; then
        check_slot="$check_slot_dir/slot$i"; echo "$PWD" > "$check_slot/owner"; return 0
      fi
    done
    [ $waited -eq 0 ] && echo "     waiting for a test slot ($CHECK_SLOTS busy: $(cat "$check_slot_dir"/*/owner 2> /dev/null | tr '\n' ' '))"
    waited=1; sleep 15
  done
}

release_check_slot() { [ -n "$check_slot" ] && rm -rf "$check_slot"; check_slot=""; }
