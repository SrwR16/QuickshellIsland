#!/usr/bin/env bash
# Usage: wallpaper.sh <path>
# Sets wallpaper, generates Matugen palette, applies theme.
# Quickshell auto-reloads when Theme.qml changes (QML tooling watches files).
set -euo pipefail

WALL="$1"
[ -n "$WALL" ] && [ -f "$WALL" ] || { echo "wallpaper.sh: file not found: $WALL" >&2; exit 1; }

export PATH="$HOME/.cargo/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

if command -v awww &>/dev/null; then
  awww img "$WALL"
elif command -v feh &>/dev/null; then
  feh --bg-fill "$WALL"
fi

if command -v matugen &>/dev/null; then
  matugen image "$WALL" -m dark --prefer darkness -c "$HOME/.config/matugen/config.toml" 2>/dev/null || true
  if [ -f "$HOME/.cache/matugen/Theme.qml" ]; then
    cp "$HOME/.cache/matugen/Theme.qml" "$HOME/.config/quickshell/core/Theme.qml"
  fi
fi
