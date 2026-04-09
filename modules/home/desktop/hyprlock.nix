# =============================================================================
# Hyprlock Configuration
# =============================================================================
# Lock screen for Hyprland with vague theme styling.
# =============================================================================
{ pkgs, colors, ... }:
let
  c = colors.vague;

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
          path = "~/NixConfig/wallpapers/517020ldsdl.jpg";
          blur_passes = 3;
          blur_size = 7;
          noise = 0.0117;
          contrast = 0.8916;
          brightness = 0.8172;
          vibrancy = 0.1696;
          vibrancy_darkness = 0.0;
        }
      ];

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          dots_size = 0.2;
          dots_spacing = 0.35;
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
          text = "cmd[update:1000] echo \"${span c.accent "$(date +'%H:%M')"}\"";
          color = rgb c.fg;
          font_size = 72;
          font_family = "JetBrains Mono";
          position = "0, 200";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "cmd[update:1000] echo \"${span c.purple "$(date +'%A, %d %B')"}\"";
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
