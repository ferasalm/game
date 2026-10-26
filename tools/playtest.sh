#!/usr/bin/env bash
# Runs the game with playtest capture and mirrors its output into inbox/playtest/game.log.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p inbox/playtest
"$(tools/godot.sh)" --path . "$@" 2>&1 | tee inbox/playtest/game.log
