# Tmux setup.
# Plugins, session management, window picking, and a user service.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    let
      c = config.theme.colours;

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

    in
    {
      config = {
        environment.systemPackages = [
          pkgs.sesh
          tmuxWindowPicker
          tmuxResurrectSave
          tmuxSeshPicker
          tmuxSeshKiller
          tmuxYaziPopup
          tmuxJjuiPopup
          tmuxNaviPopup
          pkgs.tmuxPlugins.yank
          pkgs.tmuxPlugins.resurrect
          pkgs.tmuxPlugins.extrakto
          pkgs.tmuxPlugins.tmux-fzf
          pkgs.tmuxPlugins.tmux-floax
          pkgs.tmuxPlugins.jump
          pkgs.yazi
        ];

        programs.tmux = {
          enable = true;
          shortcut = "`";
          keyMode = "vi";
          baseIndex = 1;
          clock24 = true;
          escapeTime = 5;
          terminal = "tmux-256color";
          historyLimit = 50000;

          extraConfig = ''
            set-option -g prefix `
            bind-key ` send-prefix

            # Use Fish as the default shell.
            set -g default-shell "${pkgs.unstable.fish}/bin/fish"

            # Keep tools available to tmux, tmux-fzf, and sesh.
            set-environment -g PATH "/etc/profiles/per-user/${config.username}/bin:/run/current-system/sw/bin:${pkgs.bash}/bin:${pkgs.fzf}/bin:${pkgs.tmux}/bin:${pkgs.sesh}/bin:${pkgs.zoxide}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:${pkgs.findutils}/bin:${pkgs.git}/bin:${pkgs.procps}/bin:${pkgs.wl-clipboard}/bin:${pkgs.jujutsu}/bin:${pkgs.jjui}/bin:$PATH"
            set-environment -g TMUX_FZF_PREVIEW 0

            # Stop tmux from taking Ctrl keys.
            unbind C-b
            unbind C-z

            # Plugin settings. These must come before the plugin is loaded.
            set -g @extrakto_key 'u'

            set -g @jump-key 'space'

            # Resurrect snapshot and restore.
            set -g @resurrect-save-key 'S'
            set -g @resurrect-restore-key 'R'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-processes 'nvim vim vi btop yazi jjui ssh man less bat cat fish bash python node cargo'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-hook-post-save-all '${tmuxResurrectSave}/bin/tmux-resurrect-save'

            # tmux-fzf.
            set-environment -g TMUX_FZF_LAUNCH_KEY 'f'
            set -g @tmux-fzf-launch-key 'f'
            set -g @tmux-fzf-options '-p -w 80% -h 60% -m --no-preview'
            set -g @tmux-fzf-preview '0'
            set -g @tmux-fzf-order 'command:session:window:pane:keybinding:clipboard:process'

            # tmux-floax scratch terminal on prefix and t.
            unbind t
            set -g @floax-width '80%'
            set -g @floax-height '80%'
            set -g @floax-border-color "#${c.border}"
            set -g @floax-text-color "#${c.fg}"
            set -g @floax-bind 't'
            set -g @floax-bind-menu 'P'
            set -g @floax-change-path 'true'

            # Load plugins asynchronously to avoid startup deadlocks in tmux 3.6.
            run-shell "${pkgs.tmuxPlugins.yank}/share/tmux-plugins/yank/yank.tmux"
            run-shell "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux"
            run-shell "${pkgs.tmuxPlugins.extrakto}/share/tmux-plugins/extrakto/extrakto.tmux"
            run-shell -b "${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/main.tmux"
            run-shell -b "${pkgs.tmuxPlugins.tmux-floax}/share/tmux-plugins/tmux-floax/floax.tmux"
            run-shell -b "${pkgs.tmuxPlugins.jump}/share/tmux-plugins/jump/tmux-jump.tmux"

            # Sesh session manager on prefix and K.
            bind-key K display-popup -E -w 80% -h 70% "${tmuxSeshPicker}/bin/tmux-sesh-picker"

            # Go to the last session without losing history.
            bind -N "last-session (via sesh)" BTab run-shell "${pkgs.sesh}/bin/sesh last"

            bind-key S run-shell "${tmuxResurrectSave}/bin/tmux-resurrect-save run"
            bind-key R run-shell "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh"

            bind-key w choose-tree -sZ

            bind-key o display-popup -E -w 75% -h 65% "${tmuxWindowPicker}/bin/tmux-window-picker"

            # Navi cheatsheet popup. Prefix and Ctrl-g.
            bind-key C-g display-popup -E -w 80% -h 70% -d "#{pane_current_path}" "${tmuxNaviPopup}/bin/tmux-navi-popup #{pane_id}"
            bind-key N command-prompt -p "New Session Name:" "if-shell -F '%1' 'new-session -A -s \"%1\"'"

            # Smart command mode and the tmux-fzf launcher.
            set -g status-keys emacs
            bind-key : command-prompt -T command
            bind-key \; run-shell -b "TMUX_FZF_OPTIONS='-p -w 80% -h 60% --no-preview' TMUX_FZF_PREVIEW=0 TMUX_FZF_CLIENT='#{client_tty}' ${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/command.sh"

            # Floating jjui popup on prefix and g. Press again to close.
            bind g if-shell -F '#{==:#{session_name},popup-jjui}' \
              'detach-client' \
              'if-shell -F "#{m/r:^(popup-|scratch),#{session_name}}" "detach-client" "display-popup -d \"#{pane_current_path}\" -w 85% -h 85% -E \"${tmuxJjuiPopup}/bin/tmux-jjui-popup \\\"#{pane_current_path}\\\"\""'

            # True colour support.
            set-option -a terminal-features ",xterm-256color:RGB,xterm-kitty:RGB,ghostty:RGB,foot:RGB,alacritty:RGB,tmux-256color:RGB,*:RGB"
            set-option -a terminal-features ",*:hyperlinks"
            set-option -a terminal-overrides ",xterm-256color:Tc,xterm-kitty:Tc,ghostty:Tc,foot:Tc,alacritty:Tc,tmux-256color:Tc,*:Tc"
            set-option -a terminal-overrides ',*:Smulx=\E[4::%p1%dm'
            set-option -a terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d;m'

            # Keep truecolor in every tmux window and pane.
            set-environment -g COLORTERM "truecolor"
            set -g update-environment "DISPLAY SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY SWAYSOCK WAYLAND_DISPLAY PATH COLORTERM TERM TERM_PROGRAM KITTY_WINDOW_ID KITTY_PID"
            set -gw xterm-keys on
            set -s extended-keys on
            set -g allow-passthrough all
            set -s set-clipboard on
            set -g focus-events on
            set -g mouse on
            set -g detach-on-destroy off
            set -s exit-empty off
            set -g aggressive-resize on

            # Window numbering.
            set -g pane-base-index 1
            set -g renumber-windows on
            setw -g automatic-rename on
            setw -g automatic-rename-format '#{b:pane_current_command}'

            # Neovim style splits. v is side by side, s is top and bottom.
            unbind '"'
            unbind %
            bind v split-window -h -c "#{pane_current_path}"
            bind | split-window -h -c "#{pane_current_path}"
            bind s split-window -v -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind _ split-window -f -v -c "#{pane_current_path}"
            bind \\ split-window -f -h -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
            bind n new-window -c "#{pane_current_path}"

            # Pane lifecycle and zoom.
            bind q display-panes
            bind Q kill-window
            bind X confirm-before -p "Kill session #S? (y/n)" kill-session
            bind x kill-pane
            bind z resize-pane -Z
            bind = select-layout tiled
            bind y setw synchronize-panes \; display-message "Pane synchronisation: #{?pane_synchronized,ON,OFF}"
            bind e if-shell -F '#{==:#{session_name},popup-yazi}' \
              'detach-client' \
              'if-shell -F "#{m/r:^(popup-|scratch),#{session_name}}" "detach-client" "display-popup -d \"#{pane_current_path}\" -w 85% -h 85% -E \"${tmuxYaziPopup}/bin/tmux-yazi-popup \\\"#{pane_current_path}\\\"\""'
            bind B break-pane
            bind b set -g status \; display-message "Status bar toggled"
            bind TAB last-window
            bind m set -g mouse \; display-message "Mouse mode: #{?mouse,ON,OFF}"

            # Window swapping.
            bind -r < swap-window -d -t -1
            bind -r > swap-window -d -t +1

            # Join and swap panes.
            bind J choose-window 'join-pane -h -s "%%"'
            bind j choose-window 'join-pane -v -s "%%"'
            bind -r '{' swap-pane -U
            bind -r '}' swap-pane -D

            # Resize panes with capital H and L, or Alt with hjkl.
            bind -r H resize-pane -L 5
            bind -r L resize-pane -R 5
            bind -r M-h resize-pane -L 5
            bind -r M-j resize-pane -D 5
            bind -r M-k resize-pane -U 5
            bind -r M-l resize-pane -R 5

            # Alt and a number selects a window directly.
            bind -n M-1 select-window -t 1
            bind -n M-2 select-window -t 2
            bind -n M-3 select-window -t 3
            bind -n M-4 select-window -t 4
            bind -n M-5 select-window -t 5
            bind -n M-6 select-window -t 6
            bind -n M-7 select-window -t 7
            bind -n M-8 select-window -t 8
            bind -n M-9 select-window -t 9
            bind -n M-H previous-window
            bind -n M-L next-window
            bind [ previous-window
            bind ] next-window

            # Alt with hjkl moves between panes.
            bind -n M-h select-pane -L
            bind -n M-j select-pane -D
            bind -n M-k select-pane -U
            bind -n M-l select-pane -R

            # Alt passthrough on prefix and a. Alt with hjkl then reaches
            # Neovim, which uses it for mini.move.
            bind a if-shell -F '#{==:#{client_key_table},passthrough}' \
              'switch-client -T root \; display-message "ALT NAVIGATION: ENABLED"' \
              'switch-client -T passthrough \; display-message "ALT PASSTHROUGH: ON (Leader+a or Esc to exit)"'

            bind -T passthrough M-h send-keys M-h \; switch-client -T passthrough
            bind -T passthrough M-j send-keys M-j \; switch-client -T passthrough
            bind -T passthrough M-k send-keys M-k \; switch-client -T passthrough
            bind -T passthrough M-l send-keys M-l \; switch-client -T passthrough
            bind -T passthrough Escape switch-client -T root \; display-message "ALT NAVIGATION: ENABLED"
            bind -T passthrough ` switch-client -T root \; display-message "ALT NAVIGATION: ENABLED"
            bind -T passthrough a switch-client -T root \; display-message "ALT NAVIGATION: ENABLED"

            # Reload the config.
            bind-key r run-shell 'if [ -f ~/.config/tmux/tmux.conf ]; then tmux source-file ~/.config/tmux/tmux.conf && tmux display-message "Reloaded ~/.config/tmux/tmux.conf"; elif [ -f ~/.tmux.conf ]; then tmux source-file ~/.tmux.conf && tmux display-message "Reloaded ~/.tmux.conf"; elif [ -f /etc/tmux.conf ]; then tmux source-file /etc/tmux.conf && tmux display-message "Reloaded /etc/tmux.conf"; else tmux display-message "Failed to reload tmux config"; fi'
            # Clear scrollback and redraw the screen.
            bind C-k send-keys -R \; send-keys C-l \; clear-history

            # Vi copy mode and scrollback search.
            set -g word-separators " @()[]{}':\""
            bind-key V copy-mode
            bind / copy-mode \; send-keys ?
            bind-key -T copy-mode-vi / command-prompt -i -I "#{pane_search_string}" -p "(search down)" { send-keys -X search-forward-incremental "%%%" }
            bind-key -T copy-mode-vi ? command-prompt -i -I "#{pane_search_string}" -p "(search up)" { send-keys -X search-backward-incremental "%%%" }
            bind-key -T copy-mode-vi v send-keys -X begin-selection
            bind-key -T copy-mode-vi V send-keys -X select-line
            bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true"
            bind-key -T copy-mode-vi Y send-keys -X copy-pipe-line-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true"
            bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true"
            bind-key -T copy-mode-vi DoubleClick1Pane select-pane \; send-keys -X select-word \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true"
            bind-key -T copy-mode-vi TripleClick1Pane select-pane \; send-keys -X select-line \; run-shell -d 0.3 \; send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true"
            bind-key -T root DoubleClick1Pane select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" "send-keys -M" "copy-mode -H ; send-keys -X select-word ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel '${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true'"
            bind-key -T root TripleClick1Pane select-pane -t = \; if-shell -F "#{||:#{pane_in_mode},#{mouse_any_flag}}" "send-keys -M" "copy-mode -H ; send-keys -X select-line ; run-shell -d 0.3 ; send-keys -X copy-pipe-and-cancel '${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true'"
            bind-key -T copy-mode-vi WheelUpPane send-keys -X -N 2 scroll-up
            bind-key -T copy-mode-vi WheelDownPane send-keys -X -N 2 scroll-down
            bind p paste-buffer -p

            # Status bar.
            set -g status-position top
            set -g status-interval 5
            set -g status-justify left
            set -g status-style "fg=#${c.fg},bg=#${c.bg}"

            set -g status-left-length 60
            set -g status-left "#{?client_prefix,#[fg=#${c.bg}]#[bg=#${c.yellow}]#[bold] ⌨ LEADER #[default] ,}#{?#{==:#{client_key_table},passthrough},#[fg=#${c.bg}]#[bg=#${c.red}]#[bold] ALT-PASSTHROUGH #[default] ,}#[fg=#${c.bg},bg=#${c.accent},bold] #S #[default] #{?pane_synchronized,#[fg=#${c.bg},bg=#${c.red},bold] SYNC #[default] ,}"

            setw -g window-status-format "#[fg=#${c.fgMid}] #I #W "
            setw -g window-status-current-format "#[fg=#${c.accent},bg=#${c.bgSubtle},bold] #I #W #[default]"
            setw -g window-status-separator ""
            setw -g window-status-activity-style "fg=#${c.yellow}"
            setw -g window-status-bell-style "fg=#${c.red},bold"

            set -g status-right-length 100
            set -g status-right "#{?window_zoomed_flag,#[fg=#${c.bg},bg=#${c.yellow},bold] ZOOM #[default] ,}#[fg=#${c.teal},bold]#(${tmuxPathFormatter} '#{pane_current_path}') "

            # Pane borders and popup borders.
            set -g pane-border-lines single
            set -g pane-border-style "fg=#${c.border}"
            set -g pane-active-border-style "fg=#${c.accent}"
            set -g popup-border-lines rounded
            set -g popup-border-style "fg=#${c.border}"

            # Copy mode and display pane colours.
            set -g mode-style "fg=#${c.bg},bg=#${c.accent},bold"
            set -g display-panes-colour "#${c.fgMid}"
            set -g display-panes-active-colour "#${c.accent}"
            set -g display-panes-time 3000
            set -g display-time 2500

            set -g message-style "fg=#${c.accent},bg=#${c.bgSubtle},bold"
            set -g message-command-style "fg=#${c.accent},bg=#${c.bgSubtle},bold"

            set -g visual-activity off
            set -g visual-bell off
            set -g visual-silence off
            setw -g monitor-activity off
            set -g bell-action none
          '';
        };

        # Start tmux at login.
        systemd.user.services.tmux = {
          description = "Tmux terminal multiplexer daemon";
          documentation = [ "man:tmux(1)" ];
          wantedBy = [ "default.target" ];
          environment = {
            # Match the socket directory used by programs.tmux in user shells.
            TMUX_TMPDIR = "%t";
          };
          path = with pkgs; [
            "/etc/profiles/per-user/${config.username}/bin"
            "/run/current-system/sw/bin"
            tmux
            unstable.fish
            sesh
            zoxide
            fzf
            bash
            coreutils
            procps
          ];
          serviceConfig = {
            Type = "forking";
            ExecStart = "${pkgs.tmux}/bin/tmux start-server \\; set-option -s exit-empty off";
            ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
            Restart = "on-failure";
          };
        };

        hjem.users.${config.username}.files = {
          ".config/fish/functions/ta.fish" = {
            clobber = true;
            text = ''
              function ta --description "Smart tmux session manager with sesh"
                  if test (count $argv) -gt 0
                      ${pkgs.sesh}/bin/sesh connect $argv[1]
                  else
                      ${tmuxSeshPicker}/bin/tmux-sesh-picker
                  end
              end
            '';
          };

          ".config/sesh/sesh.toml" = {
            clobber = true;
            text = ''
              [default_session]
              startup_command = "${pkgs.unstable.fish}/bin/fish"
            '';
          };
        };

        # Tmux aliases.
        programs.fish.shellAliases = {
          t = "tmux";
          tls = "tmux ls";
        };
      };
    };
}
