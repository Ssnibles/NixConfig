# =============================================================================
# Tmux Configuration
# =============================================================================
# Terminal multiplexer with vi-mode, TPM plugins, and vague colour theme.
# NOTE: TPM itself is bootstrapped outside Nix – see README.md.
# =============================================================================
{ pkgs, ... }:
let
  # ── Vague colour palette ─────────────────────────────────────────────────
  bg = "#141415";
  bg-raised = "#1c1c24";
  border = "#252530";
  fg = "#cdcdcd";
  fg-dim = "#606079";
  fg-mid = "#878787";
  accent = "#6e94b2";
  teal = "#b4d4cf";
  warn = "#f3be7c";
  error = "#d8647e";
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
      sensible
      resurrect
      continuum
      yank
      prefix-highlight
      open
      vim-tmux-navigator
    ];

    extraConfig = ''
      # ── Terminal capabilities ───────────────────────────────────────────
      set -g  default-terminal "tmux-256color"
      set -as terminal-overrides ",*:RGB"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d;m'

      # ── Usability ───────────────────────────────────────────────────────
      set  -g renumber-windows on
      setw -g pane-base-index 1
      set  -g repeat-time 500
      set  -g focus-events on
      set  -g set-titles on
      set  -g set-titles-string "#S / #W"

      # Send the prefix character itself when pressed twice
      bind ` send-prefix

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "󰞌 tmux.conf reloaded!"

      # ── Pane resizing ───────────────────────────────────────────────────
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # ── Pane splitting ──────────────────────────────────────────────────
      bind v split-window -v -c "#{pane_current_path}"
      bind h split-window -h -c "#{pane_current_path}"

      # ── Window management ───────────────────────────────────────────────
      bind x   kill-pane
      bind X   kill-window
      bind f   resize-pane -Z
      bind q   detach-client
      bind -n C-w choose-window -Z
      bind e   choose-window
      bind y   setw synchronize-panes \; display-message "Pane synchronization: #{?pane_synchronized,ON,OFF}"
      bind n   new-window -c "#{pane_current_path}"

      # ── Copy mode (vi-like) ─────────────────────────────────────────────
      bind -T copy-mode-vi v   send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y   send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi C-y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind P paste-buffer
      bind C clear-history

      # ── Vim-aware pane navigation ───────────────────────────────────────
      # Smart Ctrl+h/j/k/l: passes through to Neovim when at a split edge.
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R

      # ── Status bar ──────────────────────────────────────────────────────
      set -g status-position top
      set -g status-style    "fg=${fg},bg=${bg}"
      set -g status-justify  left
      set -g status-interval 1

      set -g status-left-length 80
      set -g status-left "#[fg=${fg},bg=${bg},bold] #S #[default] #{prefix_highlight} "

      setw -g window-status-format         "#[fg=${fg-mid},bg=${bg}] #I:#W "
      setw -g window-status-current-format "#[fg=${fg},bold,bg=${bg-raised}] #I:#W #[default]"
      setw -g window-status-separator      ""
      setw -g window-status-activity-style "fg=${warn},bg=${bg}"
      setw -g window-status-bell-style     "fg=${error},bg=${bg}"

      set -g status-right-length 150
      set -g status-right "#[fg=${fg},bg=${bg}] #{continuum_status} #[fg=${fg-mid},bg=${bg}]%H:%M #[fg=${fg},bg=${bg}] #H "

      # ── Pane borders ────────────────────────────────────────────────────
      set -g pane-border-lines        simple
      set -g pane-border-style        "fg=${fg-mid}"
      set -g pane-active-border-style "fg=${accent}"

      # ── Message bar ─────────────────────────────────────────────────────
      set -g message-style         "fg=${fg},bg=${bg-raised},bold"
      set -g message-command-style "fg=${fg},bg=${bg-raised},bold"

      # ── Bell & activity ─────────────────────────────────────────────────
      set  -g visual-activity  off
      set  -g visual-bell      off
      set  -g visual-silence   off
      setw -g monitor-activity off
      set  -g bell-action      none

      setw -g automatic-rename        on
      setw -g automatic-rename-format '#{b:pane_current_command}'

      # ── TPM plugins ─────────────────────────────────────────────────────
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
      set -g @plugin 'tmux-plugins/tmux-open'
      set -g @plugin 'christoomey/vim-tmux-navigator'

      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '1'

      set -g @prefix_highlight_fg              "${bg}"
      set -g @prefix_highlight_bg              "${warn}"
      set -g @prefix_highlight_show_copy_mode  'on'
      set -g @prefix_highlight_copy_mode_attr  "fg=${bg},bg=${teal}"
      set -g @prefix_highlight_show_sync_mode  'on'
      set -g @prefix_highlight_sync_mode_attr  "fg=${bg},bg=${error}"

      # Initialise TPM (must be last)
      run '~/.tmux/plugins/tpm/tpm'
    '';
  };
}
