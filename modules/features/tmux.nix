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
    in
    {
      config = {
        programs.tmux = {
          enable = true;
          keyMode = "vi";
          baseIndex = 1;
          escapeTime = 0;
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
            tmux-thumbs
          ];

          extraConfig = ''
            set-option -g prefix `
            bind-key ` send-prefix

            # Unbind default Ctrl shortcuts so tmux never intercepts Control keys
            unbind C-b
            unbind C-z

            # Resurrect & Continuum session options (bind S to save, R to restore without Ctrl chords)
            set -g @resurrect-save 'S'
            set -g @resurrect-restore 'R'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '10'

            # Tmux-FZF configuration
            set -g @tmux-fzf-launch-key 'F'
            set -g @tmux-fzf-order 'command:session:window:pane:keybinding:clipboard:process'

            # tmux-floax configuration
            set -g @floax-width '80%'
            set -g @floax-height '80%'
            set -g @floax-border-color "#${c.border}"
            set -g @floax-text-color "#${c.fg}"
            set -g @floax-bind 'p'
            set -g @floax-change-path 'true'

            # Modern Terminal & True Color support
            set -as terminal-features ",*:RGB"
            set -gw xterm-keys on
            set -as terminal-overrides ",*:Tc"
            set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
            set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d;m'
            set -g allow-passthrough on
            set -s set-clipboard on
            set -g focus-events on
            set -g mouse on
            set -g repeat-time 500
            set -g set-titles on
            set -g set-titles-string "#S / #W"

            # Client/session ergonomics
            set -g detach-on-destroy off
            set -g aggressive-resize on
            set -g display-time 2000
            set -g display-panes-time 1000
            set -g update-environment "DISPLAY SSH_AUTH_SOCK SSH_CONNECTION WINDOWID XAUTHORITY SWAYSOCK WAYLAND_DISPLAY"

            # Indexing & Window behavior
            setw -g pane-base-index 1
            set -g renumber-windows on
            setw -g automatic-rename on
            setw -g automatic-rename-format '#{b:pane_current_command}'

            # Smart Command Mode & Auto-Completion (: and fuzzy finder)
            set -g status-keys emacs
            bind-key : command-prompt -T command
            bind-key \; run-shell -b "TMUX_FZF_OPTIONS='-p 80%,60%' ${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/command.sh"
            bind-key S run-shell -b "TMUX_FZF_OPTIONS='-p 80%,60%' ${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/session.sh"

            # Window & Pane splitting (Neovim-style: v=side-by-side vertical split, s=top/bottom horizontal split)
            unbind '"'
            unbind %
            bind v split-window -h -c "#{pane_current_path}"
            bind | split-window -h -c "#{pane_current_path}"
            bind s split-window -v -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
            bind n new-window -c "#{pane_current_path}"

            # Pane lifecycle & zooming (Neovim / workflow inspired)
            bind q kill-pane
            bind Q kill-window
            bind o resize-pane -Z
            bind f resize-pane -Z
            bind x kill-pane
            bind = select-layout tiled
            bind y setw synchronize-panes \; display-message "Pane synchronization: #{?pane_synchronized,ON,OFF}"
            bind e choose-window
            bind B break-pane
            bind z set -g status \; display-message "Status bar toggled"

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
            bind r run-shell 'tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || tmux source-file /etc/tmux.conf' \; display-message "Tmux configuration reloaded!"
            bind K clear-history

            # Vi Copy Mode keybindings (Neovim-style clipboard integration)
            bind-key -T copy-mode-vi v send-keys -X begin-selection
            bind-key -T copy-mode-vi V send-keys -X select-line
            bind-key -T copy-mode-vi b send-keys -X rectangle-toggle
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
            bind P paste-buffer

            # Minimal Visual Styling (inspired by custom Neovim ui.lua line)
            set -g status-position top
            set -g status-interval 1
            set -g status-justify left
            set -g status-style "fg=#${c.fg},bg=#${c.bg}"

            set -g status-left-length 50
            set -g status-left "#{prefix_highlight}#[fg=#${c.bg},bg=#${c.accent},bold] #S #[default] "

            setw -g window-status-format "#[fg=#${c.fgMid}] #I #W "
            setw -g window-status-current-format "#[fg=#${c.accent},bg=#${c.bgSubtle},bold] #I #W #[default]"
            setw -g window-status-separator ""
            setw -g window-status-activity-style "fg=#${c.yellow}"
            setw -g window-status-bell-style "fg=#${c.red},bold"

            set -g status-right-length 100
            set -g status-right "#{?window_zoomed_flag,#[fg=#${c.bg},bg=#${c.yellow},bold] ZOOM #[default] ,}#[fg=#${c.teal},bold]#{b:pane_current_path} "

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
            set -g @prefix_highlight_show_sync_mode 'on'
            set -g @prefix_highlight_sync_mode_attr "fg=#${c.bg},bg=#${c.red},bold"
          '';
        };

        # Useful shell aliases for tmux
        programs.fish.shellAliases = {
          t = "tmux";
          ta = "tmux attach || tmux new";
          tls = "tmux ls";
        };
      };
    };
}
