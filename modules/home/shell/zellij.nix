# =============================================================================
# Zellij Configuration
# =============================================================================
# Terminal multiplexer configured to feel close to the existing tmux workflow:
# backtick "prefix"-style controls, vi-like pane movement, and the same palette.
# =============================================================================
{ pkgs, config, ... }:
let
  rgb = (import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; }).rgb;
in
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
      stylix {
        fg ${toString (builtins.elemAt rgb.fg 0)} ${toString (builtins.elemAt rgb.fg 1)} ${toString (builtins.elemAt rgb.fg 2)}
        bg ${toString (builtins.elemAt rgb.bg 0)} ${toString (builtins.elemAt rgb.bg 1)} ${toString (builtins.elemAt rgb.bg 2)}
        red ${toString (builtins.elemAt rgb.red 0)} ${toString (builtins.elemAt rgb.red 1)} ${toString (builtins.elemAt rgb.red 2)}
        green ${toString (builtins.elemAt rgb.green 0)} ${toString (builtins.elemAt rgb.green 1)} ${toString (builtins.elemAt rgb.green 2)}
        yellow ${toString (builtins.elemAt rgb.yellow 0)} ${toString (builtins.elemAt rgb.yellow 1)} ${toString (builtins.elemAt rgb.yellow 2)}
        blue ${toString (builtins.elemAt rgb.blue 0)} ${toString (builtins.elemAt rgb.blue 1)} ${toString (builtins.elemAt rgb.blue 2)}
        magenta ${toString (builtins.elemAt rgb.magenta 0)} ${toString (builtins.elemAt rgb.magenta 1)} ${toString (builtins.elemAt rgb.magenta 2)}
        orange ${toString (builtins.elemAt rgb.orange 0)} ${toString (builtins.elemAt rgb.orange 1)} ${toString (builtins.elemAt rgb.orange 2)}
        cyan ${toString (builtins.elemAt rgb.cyan 0)} ${toString (builtins.elemAt rgb.cyan 1)} ${toString (builtins.elemAt rgb.cyan 2)}
        black ${toString (builtins.elemAt rgb.black 0)} ${toString (builtins.elemAt rgb.black 1)} ${toString (builtins.elemAt rgb.black 2)}
        white ${toString (builtins.elemAt rgb.white 0)} ${toString (builtins.elemAt rgb.white 1)} ${toString (builtins.elemAt rgb.white 2)}
      }
    }
    theme "stylix"

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

        bind "q" { CloseFocus; SwitchToMode "Normal"; }
        bind "Q" { CloseTab; SwitchToMode "Normal"; }
        bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
        bind "x" { Detach; SwitchToMode "Normal"; }
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
