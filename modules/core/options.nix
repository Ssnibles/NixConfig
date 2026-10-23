# Global options and shared defaults.
# Values here use lib.mkDefault, so a host can override them normally. Only put a
# value in a host file when it really differs between hosts.
{ ... }:
{
  nixos.modules.shared =
    { lib, ... }:
    {
      options = {
        username = lib.mkOption {
          type = lib.types.str;
          default = "josh";
          description = "Primary user account name used across system evaluation.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.str;
          default = "blackbird.jpg";
          description = "Active wallpaper filename located in assets/wallpapers/.";
        };

        wallpaper-destinations = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          apply = lib.unique;
          description = "Target user relative paths where active wallpaper should be deployed.";
        };
      };

      options.nixos.hostRole = lib.mkOption {
        type = lib.types.enum [
          "desktop"
          "laptop"
        ];
        default = "desktop";
        description = "Which hardware group this host belongs to; used by shared modules that need host-specific behaviour.";
      };

      # Shared defaults for all hosts. Per host overrides are at the bottom.
      config = lib.mapAttrsRecursive (_: lib.mkDefault) {
        theme.active = "vague";
        theme.fonts = {
          sans = "SF Pro Text";
          monospace = "Maple Mono NR NF";
          serif = "Instrument Serif";
        };

        features = {
          # Per host: the desktop uses Hyprland, the laptop uses local Mango.
          hyprland.enable = false;
          mangowc.enable = true;
          mangowc.local = false;
          niri.enable = false;
          quickshell.enable = true;
          vicinae.enable = true;
          shikane.enable = true;

          # The browser is chosen by whichever one below sets defaultBrowser.
          # Helium wins if both are enabled.
          default-apps = {
            enable = true;
            editor = "nvim";
            fileManager = "thunar.desktop";
          };

          helium = {
            enable = true;
            defaultBrowser = true;
          };
          firefox = {
            enable = false;
            defaultBrowser = true;
          };

          kitty = {
            enable = true;
            defaultTerminal = true;
          };
          foot.enable = false;

          spotify.enable = true;
          frame.enable = true;
          hermes.enable = false;
          wramp.enable = false;
          # Minecraft is a desktop only module, enabled in the desktop block.
          pi-agent = {
            enable = true;
            interactiveChoice = true;
            gitCheckpoint = true;
            protectedPaths = true;
            defaultProvider = "deepseek";
            defaultModel = "deepseek-flash";
          };

          syncthing.enable = true;
          tailscale.enable = true;
          podman-vm.enable = true;
          bluetooth.enable = true;
          flatpak.enable = true;
        };
      };
    };

  # Overrides that differ between hosts. Hardware details stay in
  # modules/hosts/<host>/.
  nixos.modules.desktop = {
    features.hyprland.enable = true;
    # Temporary: use the local Mango checkout via the mango-dev wrapper.
    # Set to false to return to the upstream package.
    features.mangowc.local = false;
    features.minecraft.enable = true;
  };

  nixos.modules.laptop = {
    features.mangowc.local = true;
    features.wramp.enable = true;
  };
}
