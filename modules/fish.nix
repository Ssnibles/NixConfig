# =============================================================================
# Fish Shell Configuration
# =============================================================================
# Includes plugins and terminal emulator configs (Ghostty/Foot).
# =============================================================================
{ pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      v = "nvim";
      c = "clear";
      rebuild = "git -C ~/NixConfig add -u && sudo nixos-rebuild switch --flake ~/NixConfig#nixos";
      update = "cd ~/NixConfig && nix flake update && sudo nixos-rebuild switch --flake .";
      get-class = "hyprctl clients | grep -A5 'class:'";
    };
    interactiveShellInit = ''
      set -g fish_greeting ""
      set -g pure_color_primary  6e94b2
      set -g pure_color_info     bb9dbd
      set -g pure_color_mute     606079
      set -g pure_color_danger   d8647e
      set -g pure_color_warning  f3be7c
      set -g pure_color_success  7fa563
    '';
    plugins = with pkgs.fishPlugins; [
      {
        name = "grc";
        src = grc.src;
      }
      {
        name = "z";
        src = z.src;
      }
      {
        name = "pure";
        src = pure.src;
      }
      {
        name = "done";
        src = done.src;
      }
    ];
  };

  xdg.configFile."ghostty/config".text = ''
    command           = ${pkgs.fish}/bin/fish
    font-size         = 12
    cursor-style      = bar
    window-decoration = false
    window-save-state = default
    window-theme      = dark
    clipboard-read    = allow
    clipboard-write   = allow
    background = 141415
    foreground = cdcdcd
    cursor-color = 6e94b2
    selection-background = 333738
    selection-foreground = cdcdcd
    palette = 0=#141415
    palette = 1=#d8647e
    palette = 2=#7fa563
    palette = 3=#f3be7c
    palette = 4=#6e94b2
    palette = 5=#bb9dbd
    palette = 6=#b4d4cf
    palette = 7=#cdcdcd
    palette = 8=#252530
    palette = 9=#d8647e
    palette = 10=#7fa563
    palette = 11=#e8b589
    palette = 12=#7e98e8
    palette = 13=#c48282
    palette = 14=#9bb4bc
    palette = 15=#cdcdcd
  '';

  xdg.configFile."foot/foot.ini".text = ''
    shell=${pkgs.fish}/bin/fish
    font=JetBrainsMono Nerd Font:size=12
    pad=20x20
    [colors-dark]
    background=141415
    foreground=cdcdcd
    selection-background=333738
    selection-foreground=cdcdcd
    regular0=141415
    regular1=d8647e
    regular2=7fa563
    regular3=f3be7c
    regular4=6e94b2
    regular5=bb9dbd
    regular6=b4d4cf
    regular7=cdcdcd
    bright0=252530
    bright1=d8647e
    bright2=7fa563
    bright3=e8b589
    bright4=7e98e8
    bright5=c48282
    bright6=9bb4bc
    bright7=cdcdcd
  '';
}
