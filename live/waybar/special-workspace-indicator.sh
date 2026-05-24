#!/usr/bin/env bash
# Special workspace indicator for Waybar
# Edit this file to customize the indicator appearance/behavior.

workspaces_json="$(hyprctl -j workspaces 2>/dev/null || echo '[]')"
ws_json="$(printf '%s' "$workspaces_json" | jq --arg ws "special:work" 'map(select(.name == $ws)) | .[0] // {}')"
visible="$(printf '%s' "$ws_json" | jq -r '.visible // false')"
count="$(printf '%s' "$ws_json" | jq -r '.windows // 0')"

if [ "$visible" = "true" ]; then
  class="active"
  text="󱂬 $count"
  tooltip="Special workspace (work) is visible"
elif [ "$count" -gt 0 ]; then
  class="occupied"
  text="󱂬 $count"
  tooltip="Special workspace (work) has $count window(s)"
else
  class="empty"
  text="󱂬"
  tooltip="Special workspace (work) is empty"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
