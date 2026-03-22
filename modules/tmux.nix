# =============================================================================
# Tmux Configuration Module
# =============================================================================
{ pkgs, ... }:
let
  # ── Color Palette (vague theme) ───────────────────────────────────────────
  vague_bg = "#141415";
  vague_bg_raised = "#1c1c24";
  vague_border = "#252530";
  vague_fg = "#cdcdcd";
  vague_fg_dim = "#606079";
  vague_fg_mid = "#878787";
  vague_accent = "#6e94b2";
  vague_teal = "#b4d4cf";
  vague_purple = "#bb9dbd";
  vague_warn = "#f3be7c";
  vague_error = "#d8647e";
  vague_plus = "#7fa563";
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

    extraConfig = ''
      # =============================================================================
      # TERMINAL CAPABILITIES
      # =============================================================================
      set -g default-terminal "tmux-256color"
      set -as terminal-overrides ",*:RGB"
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d;m'

      # =============================================================================
      # PERFORMANCE & USABILITY
      # =============================================================================
      set -g renumber-windows on
      setw -g pane-base-index 1
      set -g repeat-time 500
      set -g focus-events on
      set -g set-titles on
      set -g set-titles-string "#S / #W"

      # Send prefix character itself when pressed twice
      bind ` send-prefix

      # =============================================================================
      # CONFIGURATION RELOAD
      # =============================================================================
      bind r source-file ~/.config/tmux/tmux.conf \; display-message "󰞌 tmux.conf reloaded!"

      # =============================================================================
      # KEYBINDINGS
      # =============================================================================

      # ── Pane Navigation: REMOVED bind -n (let vim-tmux-navigator handle it) ──
      # vim-tmux-navigator will handle Ctrl+h/j/k/l and pass through to tmux
      # when at the edge of Neovim splits

      # ── Pane Resizing: Shift + H/J/K/L (WITH PREFIX, repeatable) ───────────
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # ── Pane Splitting: v (vertical) and h (horizontal) WITH PREFIX ────────
      bind v split-window -v -c "#{pane_current_path}"
      bind h split-window -h -c "#{pane_current_path}"

      # ── Window Management ───────────────────────────────────────────────────
      bind x kill-pane
      bind X kill-window
      bind f resize-pane -Z
      bind q detach-client
      bind -n C-w choose-window -Z
      bind e choose-window
      bind y setw synchronize-panes \; display-message "Pane synchronization: #{?pane_synchronized,ON,OFF}"
      bind n new-window -c "#{pane_current_path}"

      # ── Copy Mode (Vi-like) ─────────────────────────────────────────────────
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel
      bind -T copy-mode-vi C-y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind P paste-buffer

      # ── Clear History ───────────────────────────────────────────────────────
      bind C clear-history

      # =============================================================================
      # VIM-TOUCH-NAVIGATOR: Allow seamless navigation
      # =============================================================================
      # Smart pane switching with awareness of Neovim splits.
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'

      # Ensure it still works in copy-mode
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R

      # =============================================================================
      # UI & THEME: Matches vague colorscheme
      # =============================================================================

      # ── Status Bar ────────────────────────────────────────────────────────────
      set -g status-position top
      set -g status-style "fg=${vague_fg},bg=${vague_bg}"
      set -g status-justify left
      set -g status-interval 1

      # Status Left
      set -g status-left-length 80
      set -g status-left "#[fg=${vague_fg},bg=${vague_bg},bold] #S #[default] #{prefix_highlight} "

      # Window Status
      setw -g window-status-format "#[fg=${vague_fg_mid},bg=${vague_bg}] #I:#W "
      setw -g window-status-current-format "#[fg=${vague_fg},bold,bg=${vague_bg_raised}] #I:#W #[default]"
      setw -g window-status-separator ""

      # Window Activity Indicators
      setw -g window-status-activity-style "fg=${vague_warn},bg=${vague_bg}"
      setw -g window-status-bell-style "fg=${vague_error},bg=${vague_bg}"

      # Status Right
      set -g status-right-length 150
      set -g status-right "#[fg=${vague_fg},bg=${vague_bg}] #{continuum_status} #[fg=${vague_fg_mid},bg=${vague_bg}]%H:%M #[fg=${vague_fg},bg=${vague_bg}] #H "

      # ── Pane Borders ─────────────────────────────────────────────────────────
      set -g pane-border-lines simple
      set -g pane-border-style "fg=${vague_fg_mid}"
      set -g pane-active-border-style "fg=${vague_accent}"

      # ── Message/Command Bar ─────────────────────────────────────────────────
      set -g message-style "fg=${vague_fg},bg=${vague_bg_raised},bold"
      set -g message-command-style "fg=${vague_fg},bg=${vague_bg_raised},bold"

      # ── Bell & Activity Preferences ─────────────────────────────────────────
      set -g visual-activity off
      set -g visual-bell off
      set -g visual-silence off
      setw -g monitor-activity off
      set -g bell-action none

      # ── Automatic Window Renaming ───────────────────────────────────────────
      setw -g automatic-rename on
      setw -g automatic-rename-format '#{b:pane_current_command}'

      # =============================================================================
      # PLUGINS (TPM)
      # =============================================================================
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-sensible'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @plugin 'tmux-plugins/tmux-continuum'
      set -g @plugin 'tmux-plugins/tmux-yank'
      set -g @plugin 'tmux-plugins/tmux-prefix-highlight'
      set -g @plugin 'tmux-plugins/tmux-open'
      set -g @plugin 'christoomey/vim-tmux-navigator'

      # tmux-resurrect options
      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-nvim 'session'

      # tmux-continuum options
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '1'

      # tmux-prefix-highlight options
      set -g @prefix_highlight_fg "${vague_bg}"
      set -g @prefix_highlight_bg "${vague_warn}"
      set -g @prefix_highlight_show_copy_mode 'on'
      set -g @prefix_highlight_copy_mode_attr "fg=${vague_bg},bg=${vague_teal}"
      set -g @prefix_highlight_show_sync_mode 'on'
      set -g @prefix_highlight_sync_mode_attr "fg=${vague_bg},bg=${vague_error}"

      # Initialise TPM (MUST be at the very bottom)
      run '~/.tmux/plugins/tpm/tpm'
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
      yank
      prefix-highlight
      open
      vim-tmux-navigator
    ];
  };
}
