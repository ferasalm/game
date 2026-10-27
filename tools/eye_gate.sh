#!/usr/bin/env bash
# Player's-eye gate step 1: records a render wrapper non-headless and makes what a reader can look at.
# Usage: tools/eye_gate.sh <wrapper.tscn> <seconds> <out dir>   e.g. tools/eye_gate.sh res://tools/shot_neon_game.tscn 24 /tmp/eye
# Writes <out>/f*.png (30 fps movie frames), <out>/contact.png (4x4 contact sheet), <out>/clip.mp4. Never writes to inbox/.
set -uo pipefail
SCENE="${1:?wrapper scene}"; SECS="${2:?seconds}"; OUT="${3:?out dir}"
ROOT="$(git rev-parse --show-toplevel)"; cd "$ROOT" || exit 1
G="$(bash tools/godot.sh)"
FF="$(command -v ffmpeg || true)"; [ -n "$FF" ] || { echo "eye_gate: ffmpeg not found" >&2; exit 1; }
mkdir -p "$OUT"; rm -f "$OUT"/f*.png "$OUT/contact.png" "$OUT/clip.mp4"
FRAMES=$((SECS * 30))
timeout $((SECS * 60 + 120)) "$G" --path . --write-movie "$OUT/f.png" --fixed-fps 30 --quit-after "$FRAMES" "$SCENE" \
  < /dev/null > "$OUT/godot.log" 2>&1
echo "godot exit $?, frames: $(ls "$OUT"/f*.png 2>/dev/null | wc -l)"
N="$(ls "$OUT"/f*.png 2>/dev/null | wc -l)"; [ "$N" -gt 0 ] || { echo "eye_gate: no frames, see $OUT/godot.log" >&2; exit 1; }
STEP=$(( (N + 15) / 16 ))
timeout 120 "$FF" -nostdin -y -loglevel error -i "$OUT/f%08d.png" -vf "select='not(mod(n,$STEP))',scale=640:360,tile=4x4" \
  -frames:v 1 "$OUT/contact.png" < /dev/null
timeout 180 "$FF" -nostdin -y -loglevel error -framerate 30 -i "$OUT/f%08d.png" -vf scale=640:360 -pix_fmt yuv420p "$OUT/clip.mp4" < /dev/null
ls -la "$OUT/contact.png" "$OUT/clip.mp4"
