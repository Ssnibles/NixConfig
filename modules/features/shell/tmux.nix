# =============================================================================
# Tmux Multiplexer & Window Management Feature
# =============================================================================
# Tmux configuration, vi keybindings, tmux plugins (resurrect, extrakto, floax),
# sesh session manager, interactive window picker, and systemd user daemon.
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

      tmuxResurrectSave = pkgs.writeShellScriptBin "tmux-resurrect-save" ''
        set -euo pipefail

        resurrect_dir="$HOME/.tmux/resurrect"
        ${pkgs.coreutils}/bin/mkdir -p "$resurrect_dir"

        # Remove 0-byte corrupt save files
        ${pkgs.findutils}/bin/find "$resurrect_dir" -maxdepth 1 -name "tmux_resurrect_*.txt" -type f -size 0 -delete 2>/dev/null || true

        # If called directly or via keybinding, execute resurrect save script first
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

        # Sanitize Nix store paths, wrapped binaries, and Neovim --cmd flags in save file
        ${pkgs.gnused}/bin/sed -i -E \
          -e 's|/nix/store/[a-z0-9]{32}-[^/]+/bin/\.([a-zA-Z0-9_-]+)-wrapped|\1|g' \
          -e 's|/nix/store/[a-z0-9]{32}-[^/]+/bin/||g' \
          -e 's|/etc/profiles/per-user/[^/]+/bin/||g' \
          -e 's|/run/current-system/sw/bin/||g' \
          -e 's| --cmd lua [^\t\n]*||g' \
          -e 's|\.nvim-wrapped|nvim|g' \
          -e 's|\.vi-wrapped|vi|g' \
          -e 's|\.bat-wrapped|bat|g' \
          "$last_target" 2>/dev/null || true

        current_size=$(${pkgs.coreutils}/bin/stat -c %s "$last_target" 2>/dev/null || echo 0)

        # Single dummy sessions (default/bootstrap) are typically under 200 bytes.
        # Real multi-window session saves are > 250 bytes.
        if [ "$current_size" -lt 200 ]; then
          best_save=$(${pkgs.coreutils}/bin/ls -t "$resurrect_dir"/tmux_resurrect_*.txt 2>/dev/null | ${pkgs.findutils}/bin/xargs -r ${pkgs.coreutils}/bin/stat -c '%s %n' 2>/dev/null | ${pkgs.gawk}/bin/gawk '$1 > 250 {print $2}' | ${pkgs.coreutils}/bin/head -n 1 || echo "")
          if [ -n "$best_save" ] && [ -f "$best_save" ]; then
            ${pkgs.coreutils}/bin/ln -sf "$best_save" "$resurrect_dir/last"
          fi
        fi
      '';

      tmuxSeshPicker = pkgs.writeShellScriptBin "tmux-sesh-picker" ''
        set -u

        session=$(${pkgs.sesh}/bin/sesh list --icons 2>/dev/null | ${pkgs.fzf}/bin/fzf \
          --height=100% \
          --reverse \
          --border=none \
          --ansi \
          --prompt='⚡ ' \
          --header='  ^a all  ^t tmux  ^g configs  ^x zoxide  ^d kill  ^f find' \
          --bind 'tab:down,btab:up' \
          --bind 'ctrl-a:change-prompt(⚡ )+reload(${pkgs.sesh}/bin/sesh list --icons)' \
          --bind 'ctrl-t:change-prompt(🪟 )+reload(${pkgs.sesh}/bin/sesh list -t --icons)' \
          --bind 'ctrl-g:change-prompt(⚙️ )+reload(${pkgs.sesh}/bin/sesh list -c --icons)' \
          --bind 'ctrl-x:change-prompt(📁 )+reload(${pkgs.sesh}/bin/sesh list -z --icons)' \
          --bind 'ctrl-f:change-prompt(🔎 )+reload(${pkgs.findutils}/bin/find ~ -maxdepth 3 -type d -name .git 2>/dev/null | ${pkgs.gnused}/bin/sed s:/.git::)' \
          --bind 'ctrl-d:execute(${pkgs.tmux}/bin/tmux kill-session -t {2..})+change-prompt(⚡ )+reload(${pkgs.sesh}/bin/sesh list --icons)' \
          --preview-window='right:55%' \
          --preview='${pkgs.sesh}/bin/sesh preview {}' \
        2>/dev/null || echo "")

        if [ -n "$session" ]; then
          ${pkgs.sesh}/bin/sesh connect "$session"
        fi
      '';

    in
    {
      config = {
        environment.systemPackages = [
          pkgs.sesh
          tmuxResurrectSave
          tmuxSeshPicker
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

          plugins = with pkgs.tmuxPlugins; [
            yank
            resurrect
            extrakto
            tmux-fzf
            prefix-highlight
            tmux-floax
            jump
          ];

          extraConfig = ''
            set-option -g prefix `
            bind-key ` send-prefix

            # Ensure default shell is set to Fish
            set -g default-shell "${pkgs.unstable.fish}/bin/fish"

            # Ensure system tools are always available to tmux subprocesses & tmux-fzf & sesh
            set-environment -g PATH "/etc/profiles/per-user/${config.username}/bin:/run/current-system/sw/bin:${pkgs.bash}/bin:${pkgs.fzf}/bin:${pkgs.tmux}/bin:${pkgs.sesh}/bin:${pkgs.zoxide}/bin:${pkgs.coreutils}/bin:${pkgs.gnused}/bin:${pkgs.gawk}/bin:${pkgs.findutils}/bin:${pkgs.git}/bin:${pkgs.procps}/bin:${pkgs.wl-clipboard}/bin:${pkgs.lazygit}/bin:$PATH"
            set-environment -g TMUX_FZF_PREVIEW 0

            # Unbind default Ctrl shortcuts so tmux never intercepts Control keys
            unbind C-b
            unbind C-z

            # Extrakt text/URL/path extractor keybinding
            set -g @extrakto_key 'u'

            # Tmux-Jump configuration (flash.nvim / EasyMotion style jump to position)
            set -g @jump-key 'space'

            # ─── Sesh Session Manager (Prefix + K) ──────────────────────────
            bind-key K display-popup -E -w 80% -h 70% "${tmuxSeshPicker}/bin/tmux-sesh-picker"

            # Last session toggle (Prefix + L via sesh, preserves history across kills)
            bind -N "last-session (via sesh)" L run-shell "${pkgs.sesh}/bin/sesh last"

            # ─── Resurrect (manual snapshot only) ────────────────────────────
            set -g @resurrect-save-key 'S'
            set -g @resurrect-restore-key 'R'
            set -g @resurrect-strategy-nvim 'session'
            set -g @resurrect-strategy-vim 'session'
            set -g @resurrect-processes 'nvim vim vi btop yazi lazygit ssh man less bat cat'
            set -g @resurrect-capture-pane-contents 'off'
            set -g @resurrect-hook-post-save-all '${tmuxResurrectSave}/bin/tmux-resurrect-save'

            # Explicit manual session save binding using safe wrapper
            bind-key S run-shell "${tmuxResurrectSave}/bin/tmux-resurrect-save run"

            # ─── Session & Window Navigation ─────────────────────────────────
            # Interactive Session & Window Tree Picker
            bind-key w choose-tree -sZ

            # Fast Interactive Floating Window Switcher (popup)
            bind-key o display-popup -E -w 75% -h 65% "${tmuxWindowPicker}/bin/tmux-window-picker"
            bind-key N command-prompt -p "New Session Name:" "if-shell -F '%1' 'new-session -A -s \"%1\"'"

            # ─── Tmux-FZF configuration ──────────────────────────────────────
            set -g @tmux-fzf-launch-key 'f'
            set -g @tmux-fzf-options '-p -w 80% -h 60% -m --no-preview'
            set -g @tmux-fzf-preview '0'
            set -g @tmux-fzf-order 'command:session:window:pane:keybinding:clipboard:process'

            # Smart Command Mode & Auto-Completion (: and tmux-fzf launcher)
            set -g status-keys emacs
            bind-key : command-prompt -T command
            bind-key \; run-shell -b "TMUX_FZF_OPTIONS='-p -w 80% -h 60% --no-preview' TMUX_FZF_PREVIEW=0 TMUX_FZF_CLIENT='#{client_tty}' ${pkgs.tmuxPlugins.tmux-fzf}/share/tmux-plugins/tmux-fzf/scripts/command.sh"

            # ─── tmux-floax configuration ────────────────────────────────────
            set -g @floax-width '80%'
            set -g @floax-height '80%'
            set -g @floax-border-color "#${c.border}"
            set -g @floax-text-color "#${c.fg}"
            set -g @floax-bind 'P'
            set -g @floax-change-path 'true'

            # Native Floating LazyGit Popup
            bind g display-popup -d "#{pane_current_path}" -w 85% -h 85% -E "${pkgs.lazygit}/bin/lazygit"

            # ─── Terminal & True Color support ───────────────────────────────
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

            # ─── Indexing & Window behavior ──────────────────────────────────
            set -g pane-base-index 1
            set -g renumber-windows on
            setw -g automatic-rename on
            setw -g automatic-rename-format '#{b:pane_current_command}'

            # ─── Window & Pane splitting ─────────────────────────────────────
            # Neovim-style: v=side-by-side, s=top/bottom
            unbind '"'
            unbind %
            bind v split-window -h -c "#{pane_current_path}"
            bind | split-window -h -c "#{pane_current_path}"
            bind s split-window -v -c "#{pane_current_path}"
            bind - split-window -v -c "#{pane_current_path}"
            bind c new-window -c "#{pane_current_path}"
            bind n new-window -c "#{pane_current_path}"

            # ─── Pane lifecycle & zooming ────────────────────────────────────
            bind q kill-pane
            bind Q kill-window
            bind x kill-pane
            bind z resize-pane -Z
            bind = select-layout tiled
            bind y setw synchronize-panes \; display-message "Pane synchronization: #{?pane_synchronized,ON,OFF}"
            bind e choose-window
            bind B break-pane
            bind b set -g status \; display-message "Status bar toggled"
            bind TAB last-window
            bind m set -g mouse \; display-message "Mouse mode: #{?mouse,ON,OFF}"

            # ─── Window swapping & reordering ────────────────────────────────
            bind -r < swap-window -d -t -1
            bind -r > swap-window -d -t +1

            # Pane joining & fast pane swapping
            bind J choose-window 'join-pane -h -s "%%"'
            bind -r '{' swap-pane -U
            bind -r '}' swap-pane -D

            # ─── Pane resizing (Capital H, J, K, L) ──────────────────────────
            bind -r H resize-pane -L 5
            bind -r M-j resize-pane -D 5
            bind -r M-k resize-pane -U 5
            bind -r M-l resize-pane -R 5

            # ─── Window / Buffer Navigation ──────────────────────────────────
            # Alt+Number for direct window selection
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

            # ─── Alt Passthrough Mode (Prefix + a) ──────────────────────────
            # Toggle Alt Passthrough mode so Alt+j/k/h/l go directly to Neovim (for mini.move)
            bind a if-shell -F '#{==:#{key-table},passthrough}' \
              'set -u key-table \; display-message "ALT NAVIGATION: ENABLED"' \
              'set key-table passthrough \; display-message "ALT PASSTHROUGH: ON (Leader+a or Esc to exit)"'

            bind -T passthrough M-h send-keys M-h
            bind -T passthrough M-j send-keys M-j
            bind -T passthrough M-k send-keys M-k
            bind -T passthrough M-l send-keys M-l
            bind -T passthrough Escape set -u key-table \; display-message "ALT NAVIGATION: ENABLED"
            bind -T passthrough ` set -u key-table \; display-message "ALT NAVIGATION: ENABLED"

            # ─── Utility ─────────────────────────────────────────────────────
            # Quick config reload
            bind-key r run-shell 'if [ -f ~/.config/tmux/tmux.conf ]; then tmux source-file ~/.config/tmux/tmux.conf && tmux display-message "Reloaded ~/.config/tmux/tmux.conf"; elif [ -f ~/.tmux.conf ]; then tmux source-file ~/.tmux.conf && tmux display-message "Reloaded ~/.tmux.conf"; elif [ -f /etc/tmux.conf ]; then tmux source-file /etc/tmux.conf && tmux display-message "Reloaded /etc/tmux.conf"; else tmux display-message "Failed to reload tmux config"; fi'
            # Clear scrollback history
            bind C-k clear-history

            # ─── Vi Copy Mode ────────────────────────────────────────────────
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

            # ─── Status Bar Styling ──────────────────────────────────────────
            set -g status-position top
            set -g status-interval 1
            set -g status-justify left
            set -g status-style "fg=#${c.fg},bg=#${c.bg}"

            set -g status-left-length 60
            set -g status-left "#{?client_prefix,#[fg=#${c.bg}]#[bg=#${c.yellow}]#[bold] ⌨ LEADER #[default] ,}#{?#{==:#{key-table},passthrough},#[fg=#${c.bg}]#[bg=#${c.red}]#[bold] ALT-PASSTHROUGH #[default] ,}#[fg=#${c.bg},bg=#${c.accent},bold] #S #[default] #{?pane_synchronized,#[fg=#${c.bg},bg=#${c.red},bold] SYNC #[default] ,}"

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
          '';
        };

        # Systemd User Service to automatically launch tmux daemon on boot/login
        systemd.user.services.tmux = {
          description = "Tmux terminal multiplexer daemon";
          documentation = [ "man:tmux(1)" ];
          wantedBy = [ "default.target" ];
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
            ExecStart = "${pkgs.tmux}/bin/tmux start-server";
            ExecStop = "${pkgs.tmux}/bin/tmux kill-server";
            Restart = "on-failure";
          };
        };

        # Hjem Dotfiles for Sesh Fish function & configuration
        hjem.users.${config.username}.files = {
          ".config/fish/functions/ta.fish" = {
            clobber = true;
            text = ''
              function ta --description "Smart tmux session manager with sesh"
                  if test (count $argv) -gt 0
                      ${pkgs.sesh}/bin/sesh connect $argv[1]
                  else
                      set -l session (${pkgs.sesh}/bin/sesh list -i | ${pkgs.fzf}/bin/fzf --height 40% --reverse --no-sort --ansi --border-label ' sesh ' --prompt '⚡ ')
                      if test -n "$session"
                          ${pkgs.sesh}/bin/sesh connect $session
                      end
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

        # Shell aliases for tmux
        programs.fish.shellAliases = {
          t = "tmux";
          tls = "tmux ls";
        };
      };
    };
}
