#!/usr/bin/env bash
# Runs from install.sh after stow-xdg is stowed.
# Ensures Omarchy's hyprland.lua loads the stowed hypr/personal.lua.
set -euo pipefail

hyprland_lua="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.lua"
require_line='require("hypr.personal")'

# Not an Omarchy/Hyprland Lua machine (e.g. macOS): nothing to do.
[ -f "$hyprland_lua" ] || exit 0

grep -qxF "$require_line" "$hyprland_lua" && exit 0

if grep -qxF 'require("hypr.autostart")' "$hyprland_lua"; then
  sed -i.bak "/^require(\"hypr.autostart\")\$/a $require_line" "$hyprland_lua"
  rm -f "$hyprland_lua.bak"
else
  printf '\n%s\n' "$require_line" >>"$hyprland_lua"
fi

echo "Added $require_line to $hyprland_lua"
