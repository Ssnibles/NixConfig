{ pkgs, c }:
rec {
  tmuxWindowPicker = pkgs.writeShellScriptBin "tmux-window-picker" ''
    set -euo pipefail

    current_win="$(${pkgs.tmux}/bin/tmux display-message -p '#S:#I' 2>/dev/null || echo "")"
    windows="$(${pkgs.tmux}/bin/tmux list-windows -a -F '#S:#I - #W (#{pane_current_command})' 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E -v "^(''${current_win} - |(popup-[^:]+|scratch):)" || true)"

    if [ -z "$windows" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No other windows to switch to"
      sleep 0.8
      exit 0
    fi

    selected=$(printf '%s\n' "$windows" | ${pkgs.fzf}/bin/fzf \
      --prompt="Switch Window > " \
      --header="Current: ''${current_win} | Select window to jump" \
      --preview="${pkgs.tmux}/bin/tmux capture-pane -e -pt '{1}'" \
      --preview-window="right:60%" \
      --height=100% \
      --margin=0 \
      --padding=0 \
      --layout=reverse \
      --border=rounded \
      --color="bg+:#${c.bgSubtle},bg:#${c.bg},spinner:#${c.accent},hl:#${c.accent},fg:#${c.fg},header:#${c.fgMid},info:#${c.teal},pointer:#${c.accent},marker:#${c.accent},prompt:#${c.accent}")

    if [ -n "$selected" ]; then
      target=$(echo "$selected" | ${pkgs.coreutils}/bin/cut -d' ' -f1)
      ${pkgs.tmux}/bin/tmux switch-client -t "$target"
    fi
  '';

  tmuxPathFormatter = pkgs.writeShellScript "tmux-path-formatter" ''
    p="$1"
    p="''${p/#$HOME/\~}"
    if [ "''${#p}" -gt 35 ]; then
      echo "...''${p: -32}"
    else
      echo "$p"
    fi
  '';

  tmuxResurrectSave = pkgs.writeShellScriptBin "tmux-resurrect-save" ''
    set -euo pipefail

    resurrect_dir="$HOME/.tmux/resurrect"
    ${pkgs.coreutils}/bin/mkdir -p "$resurrect_dir"

    # Remove empty save files.
    ${pkgs.findutils}/bin/find "$resurrect_dir" -maxdepth 1 -name "tmux_resurrect_*.txt" -type f -size 0 -delete 2>/dev/null || true

    # Save first when the wrapper is called for a manual save.
    if [ "''${1:-}" = "--force" ] || [ "''${1:-}" = "run" ]; then
      ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh || true
    fi

    if [ ! -L "$resurrect_dir/last" ] && [ ! -f "$resurrect_dir/last" ]; then
      exit 0
    fi

    last_target=$(${pkgs.coreutils}/bin/readlink -f "$resurrect_dir/last" 2>/dev/null || echo "")

    if [ -z "$last_target" ] || [ ! -f "$last_target" ]; then
      exit 0
    fi

    # Remove Nix store paths, wrapper names, and Neovim flags from the save.
    ${pkgs.gnused}/bin/sed -i -E \
      -e 's|/nix/store/[a-z0-9]{32}-[^/]+/bin/\.([a-zA-Z0-9_-]+)-wrapped|\1|g' \
      -e 's|/nix/store/[a-z0-9]{32}-[^/]+/bin/||g' \
      -e 's|/etc/profiles/per-user/[^/]+/bin/||g' \
      -e 's|/run/current-system/sw/bin/||g' \
      -e 's| --cmd lua [^\t\n]*||g' \
      -e 's|\.nvim-wrapped|nvim|g' \
      -e 's|\.vi-wrapped|vi|g' \
      -e 's|\.bat-wrapped|bat|g' \
      -e '/\t(popup-[^\t]+|scratch)\t/d' \
      "$last_target" 2>/dev/null || true

    current_size=$(${pkgs.coreutils}/bin/stat -c %s "$last_target" 2>/dev/null || echo 0)

    # Ignore tiny saves that only contain the dummy default session.
    if [ "$current_size" -lt 200 ]; then
      best_save=$(${pkgs.coreutils}/bin/ls -t "$resurrect_dir"/tmux_resurrect_*.txt 2>/dev/null | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/stat -c '%s %n' 2>/dev/null | ${pkgs.gawk}/bin/gawk '$1 > 250 {print $2}' | ${pkgs.coreutils}/bin/head -n 1 || echo "")
      if [ -n "$best_save" ] && [ -f "$best_save" ]; then
        ${pkgs.coreutils}/bin/ln -sf "$best_save" "$resurrect_dir/last"
      fi
    fi
  '';

  tmuxSeshKiller = pkgs.writeShellScriptBin "tmux-sesh-killer" ''
    set -u
    target="''${1:-}"
    [ -z "$target" ] && exit 0

    # Strip an icon prefix from the session name, if present.
    clean_target=$(echo "$target" | ${pkgs.gnused}/bin/sed -E 's/^[^a-zA-Z0-9/~._-]+ //' | ${pkgs.gnused}/bin/sed 's/^[[:space:]]*//')

    if [ -n "$clean_target" ] && ${pkgs.tmux}/bin/tmux has-session -t "$clean_target" 2>/dev/null; then
      ${pkgs.tmux}/bin/tmux kill-session -t "$clean_target" 2>/dev/null || true
    elif [ -n "$clean_target" ]; then
      ${pkgs.zoxide}/bin/zoxide remove "$clean_target" 2>/dev/null || true
    fi
  '';

  tmuxSeshPicker = pkgs.writeShellScriptBin "tmux-sesh-picker" ''
    set -u

    session=$(${pkgs.sesh}/bin/sesh list --icons 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E -v '(popup-[a-z0-9_-]+|scratch)' | ${pkgs.fzf}/bin/fzf \
      --height=100% \
      --reverse \
      --border=none \
      --ansi \
      --prompt='⚡ ' \
      --header='  ^a all  ^t tmux  ^g configs  ^x zoxide  ^d kill/remove  ^f find' \
      --bind 'tab:down,btab:up' \
      --bind 'ctrl-a:change-prompt(⚡ )+reload(${pkgs.sesh}/bin/sesh list --icons 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E -v "(popup-[a-z0-9_-]+|scratch)")' \
      --bind 'ctrl-t:change-prompt(🪟 )+reload(${pkgs.sesh}/bin/sesh list -t --icons 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E -v "(popup-[a-z0-9_-]+|scratch)")' \
      --bind 'ctrl-g:change-prompt(⚙️ )+reload(${pkgs.sesh}/bin/sesh list -c --icons)' \
      --bind 'ctrl-x:change-prompt(📁 )+reload(${pkgs.sesh}/bin/sesh list -z --icons)' \
      --bind 'ctrl-f:change-prompt(🔎 )+reload(${pkgs.findutils}/bin/find ~ -maxdepth 3 -type d -name .git 2>/dev/null | ${pkgs.gnused}/bin/sed s:/.git::)' \
      --bind 'ctrl-d:execute(${tmuxSeshKiller}/bin/tmux-sesh-killer {})+change-prompt(⚡ )+reload(${pkgs.sesh}/bin/sesh list --icons 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E -v "(popup-[a-z0-9_-]+|scratch)")' \
      --preview-window='right:55%' \
      --preview='${pkgs.sesh}/bin/sesh preview {}' \
    2>/dev/null || echo "")

    if [ -n "$session" ]; then
      ${pkgs.sesh}/bin/sesh connect "$session"
    fi
  '';

  tmuxYaziPopup = pkgs.writeShellScriptBin "tmux-yazi-popup" ''
    set -eu
    target_dir="''${1:-$PWD}"

    ${pkgs.tmux}/bin/tmux kill-session -t popup-yazi 2>/dev/null || true
    ${pkgs.tmux}/bin/tmux new-session -s popup-yazi -c "$target_dir" \
      "${pkgs.tmux}/bin/tmux set status off; exec ${pkgs.yazi}/bin/yazi"
    ${pkgs.tmux}/bin/tmux kill-session -t popup-yazi 2>/dev/null || true
  '';

  tmuxJjuiPopup = pkgs.writeShellScriptBin "tmux-jjui-popup" ''
    set -eu
    target_dir="''${1:-$PWD}"

    ${pkgs.tmux}/bin/tmux kill-session -t popup-jjui 2>/dev/null || true
    ${pkgs.tmux}/bin/tmux new-session -s popup-jjui -c "$target_dir" \
      "${pkgs.tmux}/bin/tmux set status off; exec ${pkgs.jjui}/bin/jjui"
    ${pkgs.tmux}/bin/tmux kill-session -t popup-jjui 2>/dev/null || true
  '';

  # Show the cheatsheet in a popup, then paste the chosen command into the
  # pane that opened it without running it.
  tmuxNaviPopup = pkgs.writeShellScriptBin "tmux-navi-popup" ''
    set -eu
    target_pane="''${1:-}"
    [ -n "$target_pane" ] || exit 0

    cmd="$(${pkgs.navi}/bin/navi --print)"
    if [ -n "$cmd" ]; then
      printf '%s' "$cmd" | ${pkgs.tmux}/bin/tmux load-buffer -b navi-popup -
      ${pkgs.tmux}/bin/tmux paste-buffer -p -b navi-popup -d -t "$target_pane"
    fi
  '';
}
