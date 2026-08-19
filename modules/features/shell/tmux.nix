# =============================================================================
# Tmux Multiplexer & Window Management Feature
# =============================================================================
# Tmux configuration, vi keybindings, tmux plugins (resurrect, continuum, extrakto, floax),
# interactive window picker popup script, path formatter, and systemd user daemon.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      c = config.theme.colors;

      tmuxWindowPicker = pkgs.writeShellScriptBin "tmux-window-picker" ''
        set -euo pipefail

        current_win="$(${pkgs.tmux}/bin/tmux display-message -p '#S:#I' 2>/dev/null || echo "")"
        windows="$(${pkgs.tmux}/bin/tmux list-windows -a -F '#S:#I - #W (#{pane_current_command})' 2>/dev/null | ${pkgs.gnugrep}/bin/grep -E -v "^''${current_win} " || true)"

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
    in
    {
      config = {
        programs.tmux = {
          enable = true;
          keyMode = "vi";
          baseIndex = 1;
          clock24 = true;
          escapeTime = 5;
          terminal = "tmux-256color";
          historyLimit = 50000;

          plugins = with pkgs.tmuxPlugins; [
            yank
            resurrect
            continuum
            extrakto
            tmux-fzf
            prefix-highlight
            tmux-floax
            jump
          ];

          extraConfig = ''
            set-option -g prefix `
            bind-key ` send-prefix

            # Ensure system tools are always available to tmux subprocesses & tmux-fzf
            set-environment -g PATH "${pkgs.bash}/bin:${pkgs.fzf}/bin:${pkgs.tmux}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:${pkgs.findutils}/bin:${pkgs.git}/bin:${pkgs.procps}/bin:${pkgs.wl-clipboard}/bin:${pkgs.lazygit}/bin:$PATH"
            set-environment -g TMUX_FZF_PREVIEW 0

            # Unbind default Ctrl shortcuts so tmux never intercepts Control keys
            unbind C-b
            unbind C-z

            # Extrakt text/URL/path extractor keybinding
            set -g @extrakto_key 'u'

            # Tmux-Jump configuration (flash.nvim / EasyMotion style jump to position)
            set -g @jump-key 'space'

            # Resurrect & Continuum session options
            set -g @resurrect-save-key 'S'
            set -g @resurrect-restore-key 'R'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-processes '"~nvim" "~fish" btop yazi lazygit ssh'
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '10'

            # Explicit manual session save & restore bindings
            bind-key S run-shell "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh"
            bind-key R run-shell "${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/restore.sh"

            # Interactive Session & Window Tree Picker
            bind-key w choose-tree -sZ

            # Fast Interactive Floating Window Switcher (popup)
            bind-key o display-popup -E -w 75% -h 65% "${tmuxWindowPicker}/bin/tmux-window-picker"
            bind-key N command-prompt -p "New Session Name:" "if-shell -F '%1' 'new-session -A -s \"%1\"'"

            # Tmux-FZF configuration
            set -g @tmux-fzf-launch-key 'f'
            set -g @tmux-fzf-options '-p -w 80% -h 60% -m --no-preview'
            set -g @tmux-fzf-preview '0'
            set -g @tmux-fzf-order 'command:session:window:pane:keybinding:clipboard:process'

            # Smart Command Mode & Auto-Completion (: and tmux-fzf launcher)
            set -g status-keys emacs
            bind-key : command-prompt -T command
            bind-key \; run-shell -b "TMUX_FZF_OPTIONS='-p -w 80% -h 60% --no-preview' TMUX_FZF_PREVIEW=0 TMUX_FZF_CLIENT='#{client_tty}' ${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/command.sh"

            # tmux-floax configuration
            set -g @floax-width '80%'
            set -g @floax-height '80%'
            set -g @floax-border-color "#${c.border}"
            set -g @floax-text-color "#${c.fg}"
            set -g @floax-bind 'P'
            set -g @floax-change-path 'true'

            # Native Floating LazyGit Popup
            bind g display-popup -d "#{pane_current_path}" -w 85% -h 85% -E "${pkgs.lazygit}/bin/lazygit"

            # Modern Terminal & True Color support
            set-option -a terminal-features ",xterm-256color:RGB,xterm-kitty:RGB,ghostty:RGB,foot:RGB,alacritty:RGB,tmux-256color:RGB,*:RGB"
            set-option -a terminal-features ",*:hyperlinks"
            set-option -a terminal-overrides ",xterm-256color:Tc,xterm-kitty:Tc,ghostty:Tc,foot:Tc,alacritty:Tc,tmux-256color:Tc,*:Tc"
            set-option -a terminal-overrides ',*:Smulx=\E[4::%p1%dm'
            set-option -a terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d;m'

            # Ensure COLORTERM=truecolor is always exported to all Tmux windows/panes
            set-environment -g COLORTERM "truecolor"
            set -g update-environment "DISPLAY SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY SWAYSOCK WAYLAND_DISPLAY PATH COLORTERM"
            set -gw xterm-keys on
            set -g allow-passthrough on
            set -s set-clipboard on
            set -g focus-events on
            set -g mouse on
            set -g detach-on-destroy off
            set -g aggressive-resize on

            # Indexing & Window behavior
            set -g pane-base-index 1
            set -g renumber-windows on
            setw -g automatic-rename on
            setw -g automatic-rename-format '#{b:pane_current_command}'

            # Window & Pane splitting (Neovim-style: v=side-by-side vertical split, s=top/bottom horizontal split)
            unbind '"'
            unbind %
            bind v split-window -h -c "#{pane_current_path}"
            bind | split-window -h -c "#{pane_current_path}"
            bind s split-window -v -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
            bind n new-window -c "#{pane_current_path}"

            # Pane lifecycle & zooming
            bind q kill-pane
            bind Q kill-window
            bind z resize-pane -Z
            bind x kill-pane
            bind = select-layout tiled
            bind y setw synchronize-panes \; display-message "Pane synchronization: #{?pane_synchronized,ON,OFF}"
            bind e choose-window
            bind B break-pane
            bind b set -g status \; display-message "Status bar toggled"
            bind TAB last-window
            bind m set -g mouse \; display-message "Mouse mode: #{?mouse,ON,OFF}"

            # Window swapping & reordering
            bind -r < swap-window -d -t -1
            bind -r > swap-window -d -t +1

            # Pane joining & fast pane swapping
            bind J choose-window 'join-pane -h -s "%%"'
            bind -r '{' swap-pane -U
            bind -r '}' swap-pane -D

            # Pane resizing (Capital H, J, K, L)
            bind -r H resize-pane -L 5
            bind -r J resize-pane -D 5
            bind -r K resize-pane -U 5
            bind -r L resize-pane -R 5

            # Window / Buffer Navigation (Neovim-style, Alt-based)
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

            # Pane navigation (Alt+hjkl for seamless movement without Ctrl collisions)
            bind -n M-h select-pane -L
            bind -n M-j select-pane -D
            bind -n M-k select-pane -U
            bind -n M-l select-pane -R

            # Quick config reload & history clear
            bind-key r run-shell 'if [ -f ~/.config/tmux/tmux.conf ]; then tmux source-file ~/.config/tmux/tmux.conf && tmux display-message "Reloaded ~/.config/tmux/tmux.conf"; elif [ -f ~/.tmux.conf ]; then tmux source-file ~/.tmux.conf && tmux display-message "Reloaded ~/.tmux.conf"; elif [ -f /etc/tmux.conf ]; then tmux source-file /etc/tmux.conf && tmux display-message "Reloaded /etc/tmux.conf"; else tmux display-message "Failed to reload tmux config"; fi'
            bind K clear-history

            # Vi Copy Mode keybindings (Neovim-style clipboard integration)
            bind-key V copy-mode
            bind-key -T copy-mode-vi v send-keys -X begin-selection
            bind-key -T copy-mode-vi V send-keys -X select-line
            bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true"
            bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe "${pkgs.wl-clipboard}/bin/wl-copy 2>/dev/null || true"
            bind-key -T copy-mode-vi WheelUpPane send-keys -X -N 2 scroll-up
            bind-key -T copy-mode-vi WheelDownPane send-keys -X -N 2 scroll-down
            bind p paste-buffer -p
            bind P choose-buffer

            # Minimal Visual Styling (inspired by custom Neovim ui.lua line)
            set -g status-position top
            set -g status-interval 1
            set -g status-justify left
            set -g status-style "fg=#${c.fg},bg=#${c.bg}"

            set -g status-left-length 50
            set -g status-left "#{prefix_highlight}#[fg=#${c.bg},bg=#${c.accent},bold] #S #[default] #{?pane_synchronized,#[fg=#${c.bg},bg=#${c.red},bold] SYNC #[default] ,}"

            setw -g window-status-format "#[fg=#${c.fgMid}] #I #W "
            setw -g window-status-current-format "#[fg=#${c.accent},bg=#${c.bgSubtle},bold] #I #W #[default]"
            setw -g window-status-separator ""
            setw -g window-status-activity-style "fg=#${c.yellow}"
            setw -g window-status-bell-style "fg=#${c.red},bold"

            set -g status-right-length 100
            set -g status-right "#{?window_zoomed_flag,#[fg=#${c.bg},bg=#${c.yellow},bold] ZOOM #[default] ,}#[fg=#${c.teal},bold]#(${tmuxPathFormatter} '#{pane_current_path}') "

            # Solid pane split borders
            set -g pane-border-lines single
            set -g pane-border-style "fg=#${c.border}"
            set -g pane-active-border-style "fg=#${c.accent}"

            set -g message-style "fg=#${c.accent},bg=#${c.bgSubtle},bold"
            set -g message-command-style "fg=#${c.accent},bg=#${c.bgSubtle},bold"

            set -g visual-activity off
            set -g visual-bell off
            set -g visual-silence off
            setw -g monitor-activity off
            set -g bell-action none

            # Prefix Highlight Plugin Configuration
            set -g @prefix_highlight_output_prefix ""
            set -g @prefix_highlight_output_suffix ""
            set -g @prefix_highlight_fg "#${c.bg}"
            set -g @prefix_highlight_bg "#${c.accent}"
            set -g @prefix_highlight_show_copy_mode 'on'
            set -g @prefix_highlight_copy_mode_attr "fg=#${c.bg},bg=#${c.teal},bold"
            set -g @prefix_highlight_show_sync_mode 'off'
          '';
        };

        # Systemd User Service to automatically launch tmux daemon on boot/login
        systemd.user.services.tmux = {
          description = "Tmux terminal multiplexer daemon";
          documentation = [ "man:tmux(1)" ];
          wantedBy = [ "default.target" ];
          path = with pkgs; [
            tmux
            fzf
            bash
            coreutils
            gnused
            gawk
            findutils
            procps
            git
            wl-clipboard
            lazygit
          ];
          serviceConfig = {
            Type = "forking";
            ExecStart = "${pkgs.tmux}/bin/tmux new-session -d -s default";
            ExecStop = "${pkgs.bash}/bin/bash -c '${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh 2>/dev/null || true; ${pkgs.tmux}/bin/tmux kill-server'";
            Restart = "on-failure";
          };
        };

        # Shell aliases for tmux
        programs.fish.shellAliases = {
          t = "tmux";
          ta = "tmux attach || tmux new";
          tls = "tmux ls";
        };
      };
    };
}
