# =============================================================================
# Custom Shell Scripts
# =============================================================================
# Hyprland helper scripts and the AI commit-message generator.
# All scripts are built with writeShellScriptBin so they end up on $PATH.
# =============================================================================
{
  pkgs,
  lib,
  hostProfile,
  ...
}:
let
  fabulouslyOptimizedPack = pkgs.nix-minecraft.fetchModrinthModpack {
    pname = "fabulously-optimized";
    version = "12.0.8-mc1.21.11";
    url = "https://cdn.modrinth.com/data/1KVo5zza/versions/lwASzTsb/Fabulously.Optimized-v12.0.8.mrpack";
    side = "client";
    packHash = "sha256-iBkTKENX1TriQWHXdns3rvS/XD/gz1q6cxMT/IMyclQ=";
  };

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
      pkill -SIGUSR1 waybar
      echo "normal" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Disabled - Normal mode restored"
    else
      # ── Enable Focus Mode ────────────────────────────────────────────────
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_in 0
      ${pkgs.hyprland}/bin/hyprctl keyword general:gaps_out 0
      ${pkgs.hyprland}/bin/hyprctl keyword decoration:rounding 0
      # Toggle waybar visibility (SIGUSR1 toggles)
      pkill -SIGUSR1 waybar
      echo "focus" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Enabled - Distractions removed"
    fi
  '';

  # ── Desktop monitor brightness (DDC/CI) ───────────────────────────────────
  # Uses faster ddcutil settings and prevents key-repeat command pileups.
  ddc-brightness = pkgs.writeShellScriptBin "ddc-brightness" ''
    set -euo pipefail

    case "''${1:-}" in
      up) direction="+" ;;
      down) direction="-" ;;
      *)
        echo "Usage: ddc-brightness <up|down>" >&2
        exit 2
        ;;
    esac

    lock_file="''${XDG_RUNTIME_DIR:-/tmp}/ddc-brightness.lock"
    exec 9>"$lock_file"
    ${pkgs.util-linux}/bin/flock -n 9 || exit 0

    exec ${pkgs.ddcutil}/bin/ddcutil --sleep-multiplier 0.1 setvcp --noverify 10 "$direction" 5
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

  # ── Install/update Fabulously Optimized in Prism Launcher ─────────────
  setup-fo-prism = pkgs.writeShellScriptBin "setup-fo-prism" ''
    set -euo pipefail

    prism_root="''${XDG_DATA_HOME:-$HOME/.local/share}/PrismLauncher"
    instance_id="fabulously-optimized-1.21.11"
    instance_dir="$prism_root/instances/$instance_id"
    source_pack="${fabulouslyOptimizedPack}"
    deps_json="$instance_dir/.minecraft/config/fabric_loader_dependencies.json"

    mkdir -p "$instance_dir/.minecraft"
    cp -rT "$source_pack" "$instance_dir/.minecraft"
    chmod -R u+rwX "$instance_dir/.minecraft"

    game_version="1.21.11"
    loader_version="0.18.5"
    lwjgl_version="3.3.3"
    if [ -f "$deps_json" ]; then
      game_version="$(${pkgs.jq}/bin/jq -r '.minecraft // "1.21.11"' "$deps_json")"
      loader_version="$(${pkgs.jq}/bin/jq -r '.fabric_loader // "0.18.5"' "$deps_json")"
    fi

    minecraft_meta="$prism_root/meta/net.minecraft/$game_version.json"
    if [ -f "$minecraft_meta" ]; then
      inferred_lwjgl="$(${pkgs.jq}/bin/jq -r '
        .requires[]? |
        if type == "string" then
          select(startswith("org.lwjgl3:")) | split(":")[1]
        elif type == "object" and .uid == "org.lwjgl3" then
          (.equals // .suggests // .version // empty)
        else
          empty
        end
      ' "$minecraft_meta" | head -n 1)"
      if [ -n "$inferred_lwjgl" ] && [ "$inferred_lwjgl" != "null" ]; then
        lwjgl_version="$inferred_lwjgl"
      fi
    fi

    cat > "$instance_dir/instance.cfg" <<EOF
    InstanceType=OneSix
    iconKey=default
    name=Fabulously Optimized 1.21.11
    OverrideCommands=false
    OverrideConsole=false
    OverrideEnv=false
    OverrideGameTime=false
    OverrideJavaArgs=false
    OverrideJavaLocation=false
    OverrideLegacySettings=false
    OverrideMemory=false
    OverrideMiscellaneous=false
    OverrideNativeWorkarounds=false
    OverridePerformance=false
    OverrideWindow=false
    notes=
    lastLaunchTime=0
    totalTimePlayed=0
    EOF

    cat > "$instance_dir/mmc-pack.json" <<EOF
    {
      "components": [
        {
          "cachedName": "LWJGL 3",
          "cachedVersion": "$lwjgl_version",
          "uid": "org.lwjgl3",
          "version": "$lwjgl_version"
        },
        {
          "cachedName": "Minecraft",
          "cachedVersion": "$game_version",
          "important": true,
          "uid": "net.minecraft",
          "version": "$game_version"
        },
        {
          "cachedName": "Fabric Loader",
          "cachedVersion": "$loader_version",
          "uid": "net.fabricmc.fabric-loader",
          "version": "$loader_version"
        }
      ],
      "formatVersion": 1
    }
    EOF

    echo "Installed Prism instance: $instance_id"
    echo "Path: $instance_dir"
    echo "Launch with: prismlauncher -l $instance_id"
  '';
in
{
  home.packages = [
    toggle-float
    reload-waybar
    toggle-focus-mode
    aicommit
    setup-fo-prism
  ] ++ lib.optionals hostProfile.isDesktop [ ddc-brightness ];
}
