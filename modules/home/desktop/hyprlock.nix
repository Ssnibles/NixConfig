# =============================================================================
# Hyprlock Configuration
# =============================================================================
# Lock screen for Hyprland with active Stylix theme styling.
# =============================================================================
{ config, ... }:
let
  c = import ../../../lib/stylix/semantic-colors.nix { stylixColors = config.lib.stylix.colors; };

  rgb = hex: "rgb(${hex})";
  # Hyprlock/Hyprlang requires escaping '#' as '##' inside markup strings.
  span = hex: text: "<span foreground='##${hex}'>${text}</span>";
in
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
        no_fade_out = false;
      };

      background = [
        {
          monitor = "";
          color = "rgba(00000055)";
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 1;
          dots_size = 0.1;
          dots_spacing = 0.3;
          dots_center = true;
          dots_rounding = -1;
          outer_color = rgb c.border;
          inner_color = rgb c.bg;
          font_color = rgb c.fg;
          fade_on_empty = false;
          fade_timeout = 1000;
          placeholder_text = span c.fgDim "Enter password...";
          hide_input = false;
          rounding = 8;
          check_color = rgb c.accent;
          fail_color = rgb c.red;
          fail_text = span c.red "Authentication failed";
          fail_transition = 300;
          capslock_color = rgb c.yellow;
          numlock_color = -1;
          bothlock_color = -1;
          invert_numlock = false;
          swap_font_color = false;
          position = "0, -120";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] echo \"${span c.fg "$(date +'%H:%M')"}\"";
          color = rgb c.fg;
          font_size = 72;
          font_family = "JetBrains Mono";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo \"${span c.fg "$(date +'%A, %d %B')"}\"";
          color = rgb c.fg;
          font_size = 20;
          font_family = "JetBrains Mono";
          position = "0, 120";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = span c.fgDim "$USER";
          color = rgb c.fg;
          font_size = 14;
          font_family = "JetBrains Mono";
          position = "0, -200";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
