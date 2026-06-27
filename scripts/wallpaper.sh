#!/usr/bin/env bash
# Usage: wallpaper.sh <path>
# Applies the given image as the desktop wallpaper.

WALL="$1"

if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
  echo "wallpaper.sh: file not found: $WALL" >&2
  exit 1
fi

export PATH="$HOME/.cargo/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

if command -v awww &>/dev/null; then
  awww img "$WALL"
elif command -v swww &>/dev/null; then
  if swww query &>/dev/null; then
    swww img "$WALL" --transition-fps 60 --transition-type grow --transition-duration 0.5
  else
    swww-daemon &>/dev/null &
    sleep 0.3
    swww img "$WALL" --transition-fps 60 --transition-type grow --transition-duration 0.5
  fi
elif command -v feh &>/dev/null; then
  feh --bg-fill "$WALL"
elif command -v hyprctl &>/dev/null && hyprctl hyprpaper &>/dev/null; then
  hyprctl hyprpaper wallpaper ",$WALL"
else
  gsettings set org.gnome.desktop.background picture-uri "file://$WALL" 2>/dev/null || true
fi
