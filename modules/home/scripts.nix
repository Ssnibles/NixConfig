# =============================================================================
# Custom Shell Scripts
# =============================================================================
# Wayland helper scripts and the AI commit-message generator.
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
  stylixThemes = import ../../lib/stylix/themes.nix;
  stylixThemeNames = builtins.attrNames stylixThemes.themes;
  stylixThemeNamesShell = builtins.concatStringsSep " " (map lib.escapeShellArg stylixThemeNames);
  stylixThemeNamesCsv = builtins.concatStringsSep ", " stylixThemeNames;
  wallpaperPath = toString stylixThemes.wallpaper;
  awwwBin = "${pkgs.unstable.awww}/bin/awww";
  qsBin = "${pkgs.unstable.quickshell}/bin/qs";
  flakeTarget =
    if hostProfile.useDisko then
      hostProfile.hostName
    else
      "${hostProfile.hostName}-test";

  # ── Toggle floating window (Niri) ──────────────────────────────────────
  toggle-float-niri = pkgs.writeShellScriptBin "toggle-float-niri" ''
    ${pkgs.niri}/bin/niri msg action toggle-window-floating
  '';

  # ── Toggle floating window (Hyprland) ──────────────────────────────────
  toggle-float-hyprland = pkgs.writeShellScriptBin "toggle-float-hyprland" ''
    ${pkgs.hyprland}/bin/hyprctl dispatch togglefloating
  '';

  # ── Toggle floating window (auto-detect compositor) ────────────────────
  toggle-float = pkgs.writeShellScriptBin "toggle-float" ''
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      exec ${toggle-float-hyprland}/bin/toggle-float-hyprland
    else
      exec ${toggle-float-niri}/bin/toggle-float-niri
    fi
  '';

  # ── Reload Quickshell ──────────────────────────────────────────────────
  # Sends an in-process reload request so all QML updates apply instantly.
  reload-shell = pkgs.writeShellScriptBin "reload-shell" ''
    ${qsBin} ipc call quickshell reload all 2>/dev/null || true
  '';

  # ── Reload everything (Niri) ───────────────────────────────────────────
  reload-all-niri = pkgs.writeShellScriptBin "reload-all-niri" ''
    ${pkgs.niri}/bin/niri msg config
    ${qsBin} ipc call quickshell reload all 2>/dev/null || true
    ${pkgs.libnotify}/bin/notify-send "Reload" "Niri, Quickshell reloaded"
  '';

  # ── Reload everything (Hyprland) ───────────────────────────────────────
  reload-all-hyprland = pkgs.writeShellScriptBin "reload-all-hyprland" ''
    ${pkgs.hyprland}/bin/hyprctl reload
    ${qsBin} ipc call quickshell reload all 2>/dev/null || true
    ${pkgs.libnotify}/bin/notify-send "Reload" "Hyprland, Quickshell reloaded"
  '';

  # ── Reload everything (auto-detect compositor) ─────────────────────────
  reload-all = pkgs.writeShellScriptBin "reload-all" ''
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      exec ${reload-all-hyprland}/bin/reload-all-hyprland
    else
      exec ${reload-all-niri}/bin/reload-all-niri
    fi
  '';

  # ── Focus mode (Niri) ──────────────────────────────────────────────────
  toggle-focus-mode-niri = pkgs.writeShellScriptBin "toggle-focus-mode-niri" ''
    STATE_FILE="/tmp/niri-focus-mode"
    if [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "focus" ]; then
      ${pkgs.niri}/bin/niri msg action fullscreen-window
      qs ipc call bar toggle 2>/dev/null || true
      echo "normal" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Disabled"
    else
      ${pkgs.niri}/bin/niri msg action fullscreen-window
      qs ipc call bar toggle 2>/dev/null || true
      echo "focus" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Enabled"
    fi
  '';

  # ── Focus mode (Hyprland) ──────────────────────────────────────────────
  toggle-focus-mode-hyprland = pkgs.writeShellScriptBin "toggle-focus-mode-hyprland" ''
    STATE_FILE="/tmp/hyprland-focus-mode"
    if [ -f "$STATE_FILE" ] && [ "$(cat $STATE_FILE)" = "focus" ]; then
      ${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 0
      qs ipc call bar toggle 2>/dev/null || true
      echo "normal" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Disabled"
    else
      ${pkgs.hyprland}/bin/hyprctl dispatch fullscreen 0
      qs ipc call bar toggle 2>/dev/null || true
      echo "focus" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Focus Mode" "Enabled"
    fi
  '';

  # ── Focus mode (auto-detect compositor) ────────────────────────────────
  toggle-focus-mode = pkgs.writeShellScriptBin "toggle-focus-mode" ''
    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      exec ${toggle-focus-mode-hyprland}/bin/toggle-focus-mode-hyprland
    else
      exec ${toggle-focus-mode-niri}/bin/toggle-focus-mode-niri
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

  # ── Stylix theme switcher ───────────────────────────────────────────────
  # Switches lib/stylix/current-theme.nix and rebuilds the system so the
  # change is baked into a NixOS generation and survives reboots.
  # Use --apply for a quick home-manager-only switch (ephemeral).
  stylix-switch = pkgs.writeShellScriptBin "stylix-switch" ''
    set -euo pipefail

    repo_root="/home/${hostProfile.user}/NixConfig"
    theme_file="$repo_root/lib/stylix/current-theme.nix"
    available_themes=(${stylixThemeNamesShell})

    usage() {
      echo "Usage: stylix-switch <theme-name|--list|--current|--apply>" >&2
    }

    reload_ui() {
      if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        ${pkgs.hyprland}/bin/hyprctl reload >/dev/null 2>&1 || true
      elif ${pkgs.niri}/bin/niri msg focused-monitor >/dev/null 2>&1; then
        ${pkgs.niri}/bin/niri msg config >/dev/null 2>&1 || true
      else
        return 0
      fi

      ${awwwBin} img ${wallpaperPath} >/dev/null 2>&1 || true
      if [ -x "${qsBin}" ]; then
        if ! ${qsBin} ipc call quickshell reload all 2>/dev/null; then
          echo "Quickshell reload failed." >&2
        fi
      fi
    }

    apply_persist() {
      sudo nixos-rebuild switch --flake "$repo_root#${flakeTarget}"
      nh home switch
      reload_ui
    }

    apply_ephemeral() {
      nh home switch
      reload_ui
    }

    if [ ! -f "$theme_file" ]; then
      echo "Theme file not found: $theme_file" >&2
      exit 1
    fi

    current_theme="$(tr -d '"[:space:]' < "$theme_file")"

    case "''${1:-}" in
      --list)
        echo "Available themes:"
        for theme in "''${available_themes[@]}"; do
          if [ "$theme" = "$current_theme" ]; then
            printf "  %s (current)\n" "$theme"
          else
            printf "  %s\n" "$theme"
          fi
        done
        exit 0
        ;;
      --current)
        echo "$current_theme"
        exit 0
        ;;
      --apply)
        cd "$repo_root"
        apply_ephemeral
        echo "Reapplied Stylix theme via home-manager: $current_theme"
        echo "This change is ephemeral — run 'stylix-switch' without --apply to persist."
        exit 0
        ;;
      ""|-h|--help)
        usage
        echo "Available themes: ${stylixThemeNamesCsv}" >&2
        exit 2
        ;;
    esac

    selected="$1"
    found=0
    for theme in "''${available_themes[@]}"; do
      if [ "$theme" = "$selected" ]; then
        found=1
        break
      fi
    done

    if [ "$found" -ne 1 ]; then
      echo "Unknown theme: $selected" >&2
      echo "Available themes: ${stylixThemeNamesCsv}" >&2
      exit 2
    fi

    if [ "$selected" = "$current_theme" ]; then
      cd "$repo_root"
      apply_persist
      echo "Theme already active; rebuilt system: $selected"
      exit 0
    fi

    printf '"%s"\n' "$selected" > "$theme_file"

    cd "$repo_root"
    apply_persist
    echo "Switched Stylix theme to: $selected (persistent)"
  '';
in
{
  home.packages = [
    toggle-float
    toggle-float-niri
    toggle-float-hyprland
    reload-shell
    reload-all
    reload-all-niri
    reload-all-hyprland
    toggle-focus-mode
    toggle-focus-mode-niri
    toggle-focus-mode-hyprland
    aicommit
    setup-fo-prism
    stylix-switch
  ]
  ++ lib.optionals hostProfile.isDesktop [ ddc-brightness ];
}
