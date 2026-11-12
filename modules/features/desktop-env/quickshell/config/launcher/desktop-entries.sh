#!/usr/bin/env bash
# List launchable applications as JSON lines for the Quickshell launcher.
# Later directories do not override an earlier entry with the same file name.
set -euo pipefail

data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
IFS=: read -r -a data_dirs <<< "${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
dirs=(
  "$data_home"
  "${data_dirs[@]}"
  /run/current-system/sw/share
  "/etc/profiles/per-user/$USER/share"
  /var/lib/flatpak/exports/share
  "$HOME/.local/share/flatpak/exports/share"
)

declare -A seen

parse_file() {
  awk -v file="$1" '
    function esc(s) {
      gsub(/\\/, "\\\\", s)
      gsub(/"/, "\\\"", s)
      gsub(/\t/, "\\t", s)
      gsub(/\r/, "\\r", s)
      gsub(/\n/, "\\n", s)
      return s
    }
    BEGIN {
      section = ""
      actionId = ""
      actionList = ""
      name = ""
      exec = ""
      icon = ""
      comment = ""
      terminal = ""
      nodisplay = ""
      hidden = ""
      type = ""
    }
    /^\[Desktop Action / {
      actionId = $0
      sub(/^\[Desktop Action /, "", actionId)
      sub(/\]$/, "", actionId)
      section = "action"
      next
    }
    /^\[/ { section = $0; actionId = ""; next }
    section == "[Desktop Entry]" {
      line = $0
      sub(/\r$/, "", line)
      if (line ~ /^Name=/) name = substr(line, 6)
      else if (line ~ /^Exec=/) exec = substr(line, 6)
      else if (line ~ /^Icon=/) icon = substr(line, 6)
      else if (line ~ /^Comment=/) comment = substr(line, 9)
      else if (line ~ /^Terminal=/) terminal = tolower(substr(line, 10))
      else if (line ~ /^NoDisplay=/) nodisplay = tolower(substr(line, 11))
      else if (line ~ /^Hidden=/) hidden = tolower(substr(line, 8))
      else if (line ~ /^Actions=/) actionList = substr(line, 9)
      else if (line ~ /^Type=/) type = substr(line, 6)
    }
    section == "action" {
      line = $0
      sub(/\r$/, "", line)
      if (line ~ /^Name=/) actionName[actionId] = substr(line, 6)
      else if (line ~ /^Exec=/) actionExec[actionId] = substr(line, 6)
    }
    END {
      if (type != "Application") exit
      if (name == "" || exec == "") exit
      if (nodisplay == "true" || hidden == "true") exit
      gsub(/%[fFuUick]/, "", exec)
      gsub(/%%/, "%", exec)

      actionJson = ""
      count = split(actionList, ids, ";")
      for (i = 1; i <= count; i++) {
        aid = ids[i]
        if (aid == "" || !(aid in actionName) || !(aid in actionExec)) continue
        aexec = actionExec[aid]
        gsub(/%[fFuUick]/, "", aexec)
        gsub(/%%/, "%", aexec)
        if (actionJson != "") actionJson = actionJson ","
        actionJson = actionJson "{\"name\":\"" esc(actionName[aid]) "\",\"exec\":\"" esc(aexec) "\"}"
      }

      appId = file
      sub(/.*\//, "", appId)
      printf "{\"name\":\"%s\",\"exec\":\"%s\",\"icon\":\"%s\",\"comment\":\"%s\",\"terminal\":%s,\"actions\":[%s],\"file\":\"%s\",\"id\":\"%s\"}\n", esc(name), esc(exec), esc(icon), esc(comment), (terminal == "true" ? "true" : "false"), actionJson, esc(file), esc(appId)
    }
  ' "$1"
}

for dir in "${dirs[@]}"; do
  [[ -d "$dir/applications" ]] || continue
  for file in "$dir/applications"/*.desktop; do
    [[ -e "$file" ]] || continue
    base="$(basename "$file")"
    [[ -n "${seen[$base]:-}" ]] && continue
    seen[$base]=1
    parse_file "$file"
  done
done
