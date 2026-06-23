{ pkgs, config, semanticColors, ... }:
let
  inherit (semanticColors { colors = config.lib.stylix.colors; }) rgb;
  rgbValues =
    attr:
    let
      vals = rgb.${attr};
    in
    "${toString (builtins.elemAt vals 0)} ${toString (builtins.elemAt vals 1)} ${toString (builtins.elemAt vals 2)}";
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
        fg ${rgbValues "fg"}
        bg ${rgbValues "bg"}
        red ${rgbValues "red"}
        green ${rgbValues "green"}
        yellow ${rgbValues "yellow"}
        blue ${rgbValues "blue"}
        magenta ${rgbValues "magenta"}
        orange ${rgbValues "orange"}
        cyan ${rgbValues "cyan"}
        black ${rgbValues "black"}
        white ${rgbValues "white"}
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
