#!/usr/bin/env bash
# Bakes and packs Neon Glitch sprite sets, one Godot at a time (never two: LESSONS, commit memory).
# Usage: tools/art/bake_all.sh <out dir> <ids,comma> [states] [frame px] [ortho m] [colours]
# states: name:frames:seconds,... (default: the full set below). colours: 0 = full colour (default), N = quantize.
# Writes <out dir>/bake_<id>/ frames and <out dir>/sheet_<id>.jsonl; sheets go to <out dir>/sheets (never assets/ unasked).
set -uo pipefail
S="${1:?out dir}"; IDS="${2:?ids}"
STATES="${3:-idle:16:2.5,walk:12:1.333,run:10:0.933,attack:12:1.23,cast:8:0.67,hurt:4:0.33,ko:10:1.85}"
PX="${4:-256}"; ORTHO="${5:-2.6}"; COLOURS="${6:-0}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT" || exit 1
G="$(bash tools/godot.sh)"
mkdir -p "$S"
IFS=',' read -r -a LIST <<< "$IDS"
for id in "${LIST[@]}"; do
  rm -rf "$S/bake_$id"
  timeout 1200 "$G" --path . --fixed-fps 60 res://tools/bake_sprites.tscn -- "$id" "$S/bake_$id" "$STATES" "$PX" "$ORTHO" < /dev/null > "$S/bake_$id.log" 2>&1
  echo "$id baked: $(ls "$S/bake_$id" 2>/dev/null | wc -l) frames"
  python tools/art/sprite_sheet.py "$S/bake_$id" "$id" "$S/sheets" "$PX" "$ORTHO" "$COLOURS" > "$S/sheet_$id.jsonl"
  echo "$id packed: $(wc -l < "$S/sheet_$id.jsonl") states"
done
