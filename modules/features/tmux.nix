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
          shortcut = "`";
          keyMode = "vi";
          baseIndex = 1;
          escapeTime = 0;
          terminal = "tmux-256color";
          historyLimit = 50000;

          plugins = with pkgs.tmuxPlugins; [
            sensible
            vim-tmux-navigator
            yank
            resurrect
            continuum
            extrakto
            tmux-fzf
            prefix-highlight
          ];

          extraConfig = ''
            # Resurrect & Continuum session options
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '10'

            # Tmux-FZF configuration
            set -g @tmux-fzf-launch-key 'F'
            set -g @tmux-fzf-order 'command:session:window:pane:keybinding:clipboard:process'

            # Modern Terminal & True Color support
            set -as terminal-features ",*:RGB"
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

            # Indexing & Window behavior
            setw -g pane-base-index 1
            set -g renumber-windows on
            setw -g automatic-rename on
            setw -g automatic-rename-format '#{b:pane_current_command}'

            # Smart Command Mode & Auto-Completion (: and fuzzy finder)
            set -g status-keys emacs
            bind-key : command-prompt -T command
            bind-key C-: run-shell -b "TMUX_FZF_OPTIONS='-p 80%,60%' ${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/command.sh"

            # Window & Pane splitting (Neovim-style: v=side-by-side vertical split, s=top/bottom horizontal split)
            unbind '"'
            unbind %
            bind v split-window -h -c "#{pane_current_path}"
            bind | split-window -h -c "#{pane_current_path}"
            bind s split-window -v -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
            bind n new-window -c "#{pane_current_path}"

            # Pane lifecycle & zooming (Neovim <leader>wq / <leader>wo inspired)
            bind q kill-pane
            bind Q kill-window
            bind o resize-pane -Z
            bind f resize-pane -Z
            bind x kill-pane
            bind = select-layout tiled
            bind y setw synchronize-panes \; display-message "Pane synchronization: #{?pane_synchronized,ON,OFF}"
            bind e choose-window

            # Pane resizing (Capital H, J, K, L)
            bind -r H resize-pane -L 5
            bind -r J resize-pane -D 5
            bind -r K resize-pane -U 5
            bind -r L resize-pane -R 5

            # Window / Buffer Navigation (Neovim-style)
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
            bind ` last-window

            # Quick config reload & memory clear
            bind r run-shell 'tmux source-file ~/.config/tmux/tmux.conf 2>/dev/null || tmux source-file /etc/tmux.conf' \; display-message "Tmux configuration reloaded!"
            bind C clear-history

            # Vi Copy Mode keybindings (Neovim-style clipboard integration)
            bind-key -T copy-mode-vi v send-keys -X begin-selection
            bind-key -T copy-mode-vi V send-keys -X select-line
            bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
            bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
            bind-key -T copy-mode-vi C-y send-keys -X copy-pipe-and-cancel "wl-copy"
            bind P paste-buffer

            # Minimal "Out of your way" Visual Styling (from oldconf)
            set -g status-position top
            set -g status-interval 1
            set -g status-justify left
            set -g status-style "fg=#${c.fg},bg=#${c.bg}"

            set -g status-left-length 50
            set -g status-left "#{prefix_highlight}#[fg=#${c.accent},bold] #S "

            setw -g window-status-format "#[fg=#${c.fgDim}] #I #W "
            setw -g window-status-current-format "#[fg=#${c.accent},bold] #I #W "
            setw -g window-status-separator ""
            setw -g window-status-activity-style "fg=#${c.yellow}"
            setw -g window-status-bell-style "fg=#${c.red}"

            set -g status-right-length 100
            set -g status-right "#[fg=#${c.teal}] #{b:pane_current_path}  #[fg=#${c.fg}]#H  #[fg=#${c.accent},bold]%H:%M %d %b "

            set -g pane-border-lines simple
            set -g pane-border-style "fg=#${c.border}"
            set -g pane-active-border-style "fg=#${c.accent}"

            set -g message-style "fg=#${c.accent},bg=#${c.bg},bold"
            set -g message-command-style "fg=#${c.accent},bg=#${c.bg},bold"

            set -g visual-activity off
            set -g visual-bell off
            set -g visual-silence off
            setw -g monitor-activity off
            set -g bell-action none

            # Prefix Highlight Plugin Configuration
            set -g @prefix_highlight_output_prefix " PREFIX "
            set -g @prefix_highlight_output_lower ""
            set -g @prefix_highlight_fg "#${c.bg}"
            set -g @prefix_highlight_bg "#${c.accent}"
            set -g @prefix_highlight_show_copy_mode 'on'
            set -g @prefix_highlight_copy_mode_attr "fg=#${c.bg},bg=#${c.teal}"
            set -g @prefix_highlight_show_sync_mode 'on'
            set -g @prefix_highlight_sync_mode_attr "fg=#${c.bg},bg=#${c.red}"
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
