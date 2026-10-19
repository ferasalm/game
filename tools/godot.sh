#!/usr/bin/env bash
# Prints the path of the pinned Godot binary (.godot-version), downloading it once into ~/.cache/godot.
set -euo pipefail
root="$(cd "$(dirname "$0")/.." && pwd)"
ver="$(tr -d '[:space:]' < "$root/.godot-version")"
dir="${GODOT_CACHE:-$HOME/.cache/godot}/$ver"
bin="$dir/Godot_v${ver}_linux.x86_64"
if [ ! -x "$bin" ]; then
  mkdir -p "$dir"
  url="https://github.com/godotengine/godot/releases/download/$ver/Godot_v${ver}_linux.x86_64.zip"
  curl -fsSL --retry 3 -o "$dir/godot.zip" "$url" >&2
  unzip -qo "$dir/godot.zip" -d "$dir" && rm -f "$dir/godot.zip"
  chmod +x "$bin"
fi
echo "$bin"
