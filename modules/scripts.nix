# =============================================================================
# Custom Scripts
# =============================================================================
# Defines shell scripts managed by Nix.
# =============================================================================
{ pkgs, ... }:
let
  toggle-float = pkgs.writeShellScriptBin "toggle-float" ''
    IS_FLOATING=$(${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.floating')
    if [ "$IS_FLOATING" = "true" ]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch togglefloating
    else
      ${pkgs.hyprland}/bin/hyprctl dispatch togglefloating
      ${pkgs.hyprland}/bin/hyprctl dispatch resizeactive exact 60% 60%
      ${pkgs.hyprland}/bin/hyprctl dispatch centerwindow
    fi
  '';
  reload-waybar = pkgs.writeShellScriptBin "reload-waybar" ''
    pkill waybar
    waybar &
  '';
  # ── Focus Mode Toggle (gaps + waybar toggle) ───────────────────────────────
  toggle-focus-mode = pkgs.writeShellScriptBin "toggle-focus-mode" ''
    STATE_FILE="/tmp/hyprland-focus-mode"
    # Default values from your hyprland.nix
    GAPS_IN=8
    GAPS_OUT=16
    ROUNDING=16
    if [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "focus" ]; then
      # ── Restore Normal Mode ──────────────────────────────────────────────
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_in $GAPS_IN
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_out $GAPS_OUT
      ${pkgs.hyprland}/bin/hyprctl keyword decoration:rounding $ROUNDING
      # Toggle waybar visibility (SIGUSR1 toggles)
      ${pkgs.procps}/bin/pkill -SIGUSR1 waybar
      echo "normal" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Disabled - Normal mode restored"
    else
      # ── Enable Focus Mode ────────────────────────────────────────────────
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_in 0
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_out 0
      ${pkgs.hyprland}/bin/hyprctl keyword decoration:rounding 0
      # Toggle waybar visibility (SIGUSR1 toggles)
      ${pkgs.procps}/bin/pkill -SIGUSR1 waybar
      echo "focus" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Enabled - Distractions removed"
    fi
  '';
  # ── AI Commit Message Generator ───────────────────────────────────────────
  aicommit = pkgs.writeShellScriptBin "aicommit" ''
    DIFF=$(${pkgs.git}/bin/git diff --staged --no-color)

    if [ -z "$DIFF" ]; then
      echo "No staged changes." >&2
      exit 1
    fi

    DIFF=$(echo "$DIFF" | head -c 4000)

    ${pkgs.curl}/bin/curl -s --connect-timeout 2 http://127.0.0.1:11434 > /dev/null 2>&1 \
      || { echo "Ollama not reachable." >&2; exit 1; }

    RAW=$(
      ${pkgs.jq}/bin/jq -n \
        --arg model "qwen2.5-coder:1.5b" \
        --arg prompt "Write a conventional commit message for this diff. One short summary line (max 50 chars), blank line, then bullet points only if needed. Return only the message, no markdown formatting or code fences:\n\n$DIFF" \
        '{model: $model, prompt: $prompt, stream: false}' \
      | ${pkgs.curl}/bin/curl -s --max-time 30 -X POST http://127.0.0.1:11434/api/generate \
          -H "Content-Type: application/json" \
          -d @- \
      | ${pkgs.jq}/bin/jq -r '.response // empty'
    )

    # Strip markdown code fences and leading blank lines
    MESSAGE=$(echo "$RAW" \
      | ${pkgs.gnused}/bin/sed '/^[`]\{3\}/d' \
      | ${pkgs.gnused}/bin/sed '/./,$!d')

    if [ -z "$MESSAGE" ] || [ "$MESSAGE" = "null" ]; then
      echo "No response from Ollama." >&2
      exit 1
    fi

    echo "$MESSAGE"
  '';
in
{
  home.packages = [
    toggle-float
    reload-waybar
    toggle-focus-mode
    aicommit
  ];
}
