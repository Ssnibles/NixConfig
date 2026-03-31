# =============================================================================
# Custom Shell Scripts
# =============================================================================
# Hyprland helper scripts and the AI commit-message generator.
# All scripts are built with writeShellScriptBin so they end up on $PATH.
# =============================================================================
{ pkgs, ... }:
let
  # ── Toggle floating window ─────────────────────────────────────────────
  # Floats the active window and centres it at 60 % of screen size.
  toggle-float = pkgs.writeShellScriptBin "toggle-float" ''
    IS_FLOATING=$(${pkgs.hyprland}/bin/hyprctl activewindow -j \
      | ${pkgs.jq}/bin/jq -r '.floating')

    ${pkgs.hyprland}/bin/hyprctl dispatch togglefloating

    if [ "$IS_FLOATING" != "true" ]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch resizeactive exact 60% 60%
      ${pkgs.hyprland}/bin/hyprctl dispatch centerwindow
    fi
  '';

  # ── Reload Waybar ──────────────────────────────────────────────────────
  reload-waybar = pkgs.writeShellScriptBin "reload-waybar" ''
    pkill waybar
    waybar &
  '';

  # ── Focus mode ─────────────────────────────────────────────────────────
  # Toggles gaps / rounding and hides Waybar for distraction-free work.
  toggle-focus-mode = pkgs.writeShellScriptBin "toggle-focus-mode" ''
    STATE_FILE="/tmp/hyprland-focus-mode"
    GAPS_IN=8
    GAPS_OUT=16
    ROUNDING=16

    if [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "focus" ]; then
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_in   $GAPS_IN
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_out  $GAPS_OUT
      ${pkgs.hyprland}/bin/hyprctl keyword decoration:rounding $ROUNDING
      ${pkgs.procps}/bin/pkill -SIGUSR1 waybar
      echo "normal" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Disabled - Normal mode restored"
    else
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_in   0
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_out  0
      ${pkgs.hyprland}/bin/hyprctl keyword decoration:rounding 0
      ${pkgs.procps}/bin/pkill -SIGUSR1 waybar
      echo "focus" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Enabled - Distractions removed"
    fi
  '';

  # ── AI commit message generator ────────────────────────────────────────
  # Sends the staged diff to a local Ollama model and prints a commit message.
  aicommit = pkgs.writeShellScriptBin "aicommit" ''
    DIFF=$(${pkgs.git}/bin/git diff --staged --no-color)

    if [ -z "$DIFF" ]; then
      echo "No staged changes." >&2
      exit 1
    fi

    # Truncate large diffs – small models degrade beyond ~4 k chars
    DIFF=$(echo "$DIFF" | head -c 4000)

    # Bail early if Ollama is not reachable
    ${pkgs.curl}/bin/curl -s --connect-timeout 2 http://127.0.0.1:11434 \
      > /dev/null 2>&1 \
      || { echo "Ollama not reachable." >&2; exit 1; }

    RAW=$(
      ${pkgs.jq}/bin/jq -n \
        --arg model "qwen2.5-coder:1.5b" \
        --arg prompt \
"You are a commit message generator. Output ONLY a git commit message — no explanation, no preamble, no code fences.

FORMAT:
<type>[optional scope]: <description>

[optional body]

RULES:
- First line: type, optional scope in parens, colon, space, description (max 50 chars)
- Use imperative mood: add not added, fix not fixed
- Valid types: feat, fix, refactor, chore, docs, style, perf, test, build, ci, revert
- Add scope when the change is isolated: feat(auth): or fix(parser):
- Body is optional; use plain sentences, not bullet points
- Breaking changes: append ! after type/scope, e.g. feat(api)!:

EXAMPLES:
feat(auth): add OAuth2 login support
fix(parser): handle empty input without crashing
refactor(db): extract connection logic into helper
chore: update dependencies

DIFF:
\$DIFF" \
        '{model: $model, prompt: $prompt, stream: false}' \
      | ${pkgs.curl}/bin/curl -s --max-time 30 \
          -X POST http://127.0.0.1:11434/api/generate \
          -H "Content-Type: application/json" \
          -d @- \
      | ${pkgs.jq}/bin/jq -r '.response // empty'
    )

    # Strip markdown fences and leading blank lines
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
