#!/usr/bin/env bash

workspaces_json="$(hyprctl -j workspaces 2>/dev/null || echo '[]')"
ws_json="$(printf '%s' "$workspaces_json" | jq --arg ws "special:work" 'map(select(.name == $ws)) | .[0] // {}')"
visible="$(printf '%s' "$ws_json" | jq -r '.visible // false')"
count="$(printf '%s' "$ws_json" | jq -r '.windows // 0')"

if [ "$visible" = "true" ]; then
  class="active"
  icon="󰱮"
elif [ "$count" -gt 0 ]; then
  class="occupied"
  icon="󰱮"
else
  class="empty"
  icon="󰱭"
fi

if [ "$count" -gt 0 ]; then
  text="$icon $count"
else
  text="$icon"
fi

printf '{"text":"%s","class":"%s"}\n' "$text" "$class"
