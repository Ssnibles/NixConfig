# =============================================================================
# Zellij Configuration
# =============================================================================
# Terminal multiplexer configured to feel close to the existing tmux workflow:
# backtick "prefix"-style controls, vi-like pane movement, and the same palette.
# =============================================================================
{ pkgs, ... }:
{
  home.packages = [ pkgs.unstable.zellij ];

  xdg.configFile."zellij/config.kdl".text = ''
    default_shell "${pkgs.fish}/bin/fish"
    pane_frames true
    mouse_mode true
    scroll_buffer_size 10000
    copy_command "wl-copy"
    copy_on_select false
    styled_underlines true
    session_serialization true
    pane_viewport_serialization true
    scrollback_lines_to_serialize 10000
    serialization_interval 60
    show_startup_tips false
    show_release_notes false

    themes {
      vague {
        fg 205 205 205
        bg 20 20 21
        red 216 100 126
        green 127 165 99
        yellow 243 190 124
        blue 110 148 178
        magenta 187 157 189
        orange 243 190 124
        cyan 180 212 207
        black 37 37 48
        white 205 205 205
      }
    }
    theme "vague"

    keybinds {
      unbind "Ctrl b"

      shared_except "locked" {
        bind "`" { SwitchToMode "Tmux"; }
        bind "Ctrl h" { MoveFocus "Left"; }
        bind "Ctrl j" { MoveFocus "Down"; }
        bind "Ctrl k" { MoveFocus "Up"; }
        bind "Ctrl l" { MoveFocus "Right"; }
        bind "Ctrl w" {
          LaunchOrFocusPlugin "session-manager" {
            floating true
            move_to_focused_tab true
          };
          SwitchToMode "Normal";
        }
      }

      tmux {
        bind "`" { Write 96; SwitchToMode "Normal"; }
        bind "r" { SwitchToMode "Normal"; }

        bind "v" { NewPane "Down"; SwitchToMode "Normal"; }
        bind "h" { NewPane "Right"; SwitchToMode "Normal"; }

        bind "H" { Resize "Increase Left"; }
        bind "J" { Resize "Increase Down"; }
        bind "K" { Resize "Increase Up"; }
        bind "L" { Resize "Increase Right"; }

        bind "x" { CloseFocus; SwitchToMode "Normal"; }
        bind "X" { CloseTab; SwitchToMode "Normal"; }
        bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        bind "q" { Detach; SwitchToMode "Normal"; }
        bind "e" {
          LaunchOrFocusPlugin "session-manager" {
            floating true
            move_to_focused_tab true
          };
          SwitchToMode "Normal";
        }
        bind "y" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
        bind "n" { NewTab; SwitchToMode "Normal"; }
      }
    }
  '';
}
