#!/usr/bin/env bash
# Usage: wallpaper.sh <path>
# Sets wallpaper, generates Matugen palette, deploys themed configs.
# Quickshell auto-reloads when Theme.qml / colors.json changes.
set -euo pipefail

WALL="$1"
[ -n "$WALL" ] && [ -f "$WALL" ] || { echo "wallpaper.sh: file not found: $WALL" >&2; exit 1; }

export PATH="$HOME/.cargo/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

if command -v awww &>/dev/null; then
  awww img "$WALL"
elif command -v feh &>/dev/null; then
  feh --bg-fill "$WALL"
fi

if ! command -v matugen &>/dev/null; then exit 0; fi

matugen image "$WALL" -m dark --prefer darkness -c "$HOME/.config/matugen/config.toml" 2>/dev/null || true

CACHE="$HOME/.cache/matugen"

# Deploy each generated file to its config destination
deploy() {
  local src="$CACHE/$1"
  local dst="$2"
  if [ -f "$src" ]; then
    mkdir -p "$(dirname "$dst")"
    # Overwrite in-place (preserves inode) so FileView watchers detect changes
    cat "$src" > "$dst"
  fi
}

deploy "Theme.qml"        "$HOME/.config/quickshell/core/Theme.qml"
deploy "colors.json"      "$HOME/.config/quickshell/core/colors.json"
deploy "gtk3.css"         "$HOME/.config/gtk-3.0/gtk.css"
deploy "gtk4.css"         "$HOME/.config/gtk-4.0/gtk.css"
deploy "rofi.rasi"        "$HOME/.config/rofi/theme.rasi"
deploy "swaylock.conf"    "$HOME/.config/swaylock/config"
deploy "waybar.css"       "$HOME/.config/waybar/style.css"
deploy "colors.scss"      "$HOME/.config/quickshell/core/colors.scss"
