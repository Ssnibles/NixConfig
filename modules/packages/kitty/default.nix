{ self, inputs, ... }:
{
  perSystem = { pkgs, ... }: {
    packages.kitty = pkgs.kitty;
  };

  flake.nixosModules.kitty = { pkgs, lib, config, ... }: let
    inherit (config.theme.colors) bg bgRaised fg accent teal purple green yellow red orange;
  in {
    environment.systemPackages = [ pkgs.kitty ];

    hjem.users."${config.username}" = {
      files = {
        ".config/kitty/kitty.conf".text = ''
          confirm_os_window_close 0

          font_family      MartianMono Nerd Font
          bold_font        auto
          italic_font      MartianMono Nerd Font Italic
          bold_italic_font MartianMono Nerd Font Bold Italic
          font_size        12.0

          include colors.conf
        '';

        ".config/kitty/colors.conf".text = ''
          # vim:ft=kitty

          foreground              #${fg}
          background              #${bg}
          selection_foreground    #${bg}
          selection_background    #${accent}

          cursor                  #${fg}
          cursor_text_color       #${bg}

          scrollbar_handle_color  #606079
          scrollbar_track_color   #${bgRaised}

          url_color               #${accent}

          active_border_color     #${accent}
          inactive_border_color   #252530
          bell_border_color       #${yellow}

          wayland_titlebar_color system
          macos_titlebar_color system

          active_tab_foreground   #${bg}
          active_tab_background   #${accent}
          inactive_tab_foreground #${fg}
          inactive_tab_background #${bgRaised}
          tab_bar_background      #${bg}

          mark1_foreground #${bg}
          mark1_background #${accent}
          mark2_foreground #${bg}
          mark2_background #${purple}
          mark3_foreground #${bg}
          mark3_background #${teal}

          color0  #${bg}
          color8  #${bgRaised}
          color1  #${red}
          color9  #${orange}
          color2  #${green}
          color10 #${green}
          color3  #${yellow}
          color11 #${yellow}
          color4  #${accent}
          color12 #${accent}
          color5  #${purple}
          color13 #${purple}
          color6  #${teal}
          color14 #${teal}
          color7  #${fg}
          color15 #${fg}
        '';
      };
    };
  };
}
