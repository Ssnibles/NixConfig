{
  pkgs,
  config,
  semanticColors,
  ...
}:
let
  c = (semanticColors { colors = config.lib.stylix.colors; }).withHash;
in
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 50;
    historyLimit = 10000;
    keyMode = "vi";
    mouse = true;
    prefix = "`";
    shell = "${pkgs.fish}/bin/fish";
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      resurrect
      continuum
      yank
      open
      vim-tmux-navigator
    ];

    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ",*:RGB"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d;m'

      set -g renumber-windows on
      setw -g pane-base-index 1
      set -g repeat-time 500
      set -g focus-events on
      set -g set-titles on
      set -g set-titles-string "#S / #W"

      bind ` send-prefix
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded!"

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      bind v split-window -v -c "#{pane_current_path}"
      bind h split-window -h -c "#{pane_current_path}"

      bind q kill-pane
      bind Q kill-window
      bind f resize-pane -Z
      bind x detach-client
      bind -n C-w choose-window -Z
      bind e choose-window
      bind y setw synchronize-panes \; display-message "Pane synchronization: #{?pane_synchronized,ON,OFF}"
      bind n new-window -c "#{pane_current_path}"

      bind -T copy-mode-vi v   send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y   send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi C-y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind P paste-buffer
      bind C clear-history

      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \\
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R

      set -g status-position top
      set -g status-style "fg=${c.fg},bg=${c.bg}"
      set -g status-justify left
      set -g status-interval 1

      set -g status-left-length 50
      set -g status-left "#{prefix_highlight}#[fg=${c.accent},bold] #S "

      setw -g window-status-format "#[fg=${c.fgDim}] #I #W "
      setw -g window-status-current-format "#[fg=${c.accent},bold] #I #W "
      setw -g window-status-separator ""
      setw -g window-status-activity-style "fg=${c.yellow}"
      setw -g window-status-bell-style "fg=${c.red}"

      set -g status-right-length 100
      set -g status-right "#[fg=${c.teal}] #{b:pane_current_path}  #[fg=${c.fg}]#H  #[fg=${c.accent},bold]%H:%M %d %b "

      set -g pane-border-lines simple
      set -g pane-border-style "fg=${c.border}"
      set -g pane-active-border-style "fg=${c.accent}"

      set -g message-style "fg=${c.accent},bg=${c.bg},bold"
      set -g message-command-style "fg=${c.accent},bg=${c.bg},bold"

      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none

      setw -g automatic-rename on
      setw -g automatic-rename-format '#{b:pane_current_command}'

      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '1'

      set -g @prefix_highlight_output_prefix " PREFIX "
      set -g @prefix_highlight_output_lower ""
      set -g @prefix_highlight_fg "${c.bg}"
      set -g @prefix_highlight_bg "${c.accent}"
      set -g @prefix_highlight_show_copy_mode 'on'
      set -g @prefix_highlight_copy_mode_attr "fg=${c.bg},bg=${c.teal}"
      set -g @prefix_highlight_show_sync_mode 'on'
      set -g @prefix_highlight_sync_mode_attr "fg=${c.bg},bg=${c.red}"

      run-shell "${pkgs.tmuxPlugins.prefix-highlight}/share/tmux-plugins/prefix-highlight/prefix_highlight.tmux"
    '';
  };
}
