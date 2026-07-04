{ pkgs, config, ... }:
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
      # ── Terminal & Display ──────────────────────────────────────────────
      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ",*:RGB"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d;m'

      # ── General ─────────────────────────────────────────────────────────
      set -g renumber-windows on
      setw -g pane-base-index 1
      set -g repeat-time 500
      set -g focus-events on
      set -g set-titles on
      set -g set-titles-string "#S / #W"

      # ── Prefix ──────────────────────────────────────────────────────────
      bind ` send-prefix
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded!"

      # ─ Pane Navigation & Resizing ─────────────────────────────────────
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

      # ── Copy Mode ──────────────────────────────────────────────────────
      bind -T copy-mode-vi v   send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y   send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi C-y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind P paste-buffer
      bind C clear-history

      # ── Vim Integration ────────────────────────────────────────────────
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

      # ─ Status Bar Colors (Vague Theme) ────────────────────────────────
      # base01 = #1c1c24 (dark background)
      # base05 = #cdcdcd (foreground)
      # base03 = #606079 (dim foreground)
      # base0D = #6e94b2 (accent/blue)
      # base0C = #b4d4cf (teal)
      # base08 = #d8647e (red)
      # base0A = #f3be7c (yellow)
      # base02 = #252530 (border)

      set -g status-position top
      set -g status-style "fg=#cdcdcd,bg=#1c1c24"
      set -g status-justify left
      set -g status-interval 1

      set -g status-left-length 50
      set -g status-left "#{prefix_highlight}#[fg=#6e94b2,bold] #S "

      setw -g window-status-format "#[fg=#606079] #I #W "
      setw -g window-status-current-format "#[fg=#6e94b2,bold] #I #W "
      setw -g window-status-separator ""
      setw -g window-status-activity-style "fg=#f3be7c"
      setw -g window-status-bell-style "fg=#d8647e"

      set -g status-right-length 100
      set -g status-right "#[fg=#b4d4cf] #{b:pane_current_path}  #[fg=#cdcdcd]#H  #[fg=#6e94b2,bold]%H:%M %d %b "

      # ── Pane Borders ───────────────────────────────────────────────────
      set -g pane-border-lines simple
      set -g pane-border-style "fg=#252530"
      set -g pane-active-border-style "fg=#6e94b2"

      # ── Messages ───────────────────────────────────────────────────────
      set -g message-style "fg=#6e94b2,bg=#1c1c24,bold"
      set -g message-command-style "fg=#6e94b2,bg=#1c1c24,bold"

      # ── Notifications ──────────────────────────────────────────────────
      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none

      # ── Window Naming ──────────────────────────────────────────────────
      setw -g automatic-rename on
      setw -g automatic-rename-format '#{b:pane_current_command}'

      # ── Plugins ────────────────────────────────────────────────────────
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '1'

      set -g @prefix_highlight_output_prefix " PREFIX "
      set -g @prefix_highlight_output_lower ""
      set -g @prefix_highlight_fg "#1c1c24"
      set -g @prefix_highlight_bg "#6e94b2"
      set -g @prefix_highlight_show_copy_mode 'on'
      set -g @prefix_highlight_copy_mode_attr "fg=#1c1c24,bg=#b4d4cf"
      set -g @prefix_highlight_show_sync_mode 'on'
      set -g @prefix_highlight_sync_mode_attr "fg=#1c1c24,bg=#d8647e"

      run-shell "${pkgs.tmuxPlugins.prefix-highlight}/share/tmux-plugins/prefix-highlight/prefix_highlight.tmux"
    '';
  };
}
