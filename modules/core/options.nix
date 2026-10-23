# Core Global Options
# Defines central system configuration options used across all modules, and acts
# as the single settings panel for every important non-per-host feature value.
#
# Values in the `config` block below use `lib.mkDefault`, so a host's
# configuration.nix can override any of them just by setting the option
# normally. Only put a value in a host file when it genuinely differs per host.
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

      # Central Settings Panel
      # Shared defaults for all hosts. Per-host overrides are at the bottom of this file.
      config = lib.mapAttrsRecursive (_: lib.mkDefault) {
        # Appearance
        theme.active = "vague";
        theme.fonts = {
          sans = "SF Pro Text";
          monospace = "Maple Mono NR NF";
          serif = "Instrument Serif";
        };

        features = {
          # Desktop Environment
          # Per-host: desktop enables hyprland, laptop uses the local mango build.
          hyprland.enable = false;
          mangowc.enable = true;
          mangowc.local = false;
          niri.enable = false;
          quickshell.enable = true;
          vicinae.enable = true;
          shikane.enable = true;

          # Default Applications
          # default-apps.browser is derived from whichever browser below has
          # `defaultBrowser = true` (Helium wins if both are enabled).
          default-apps = {
            enable = true;
            editor = "nvim";
            fileManager = "yazi.desktop";
          };

          # Browsers
          helium = {
            enable = true;
            defaultBrowser = true;
          };
          firefox = {
            enable = false;
            defaultBrowser = true;
          };

          # Terminals
          kitty = {
            enable = true;
            defaultTerminal = true;
          };
          foot.enable = false;

          # Apps
          spotify.enable = true;
          frame.enable = true;
          hermes.enable = false;
          # Per-host: enabled on the laptop.
          wramp.enable = false;
          # minecraft is a desktop-only module; toggled in the desktop block below.
          pi-agent = {
            enable = true;
            interactiveChoice = true;
            gitCheckpoint = true;
            protectedPaths = true;
            defaultProvider = "deepseek";
            defaultModel = "deepseek-flash";
          };

          # System Services
          syncthing.enable = true;
          tailscale.enable = true;
          podman-vm.enable = true;
          bluetooth.enable = true;
          flatpak.enable = true;
        };
      };
    };

  # Per-host Feature Overrides
  # Only toggles/preferences that differ between hosts. Hardware facts (kernel
  # params, udev, power tuning, firmware) stay in modules/hosts/<host>/.
  nixos.modules.desktop = {
    features.hyprland.enable = true;
    # Temporary: build/run the local ~/mango checkout (mango-dev wrapper
    # prefers ~/mango/result). Set back to false to return to upstream.
    features.mangowc.local = false;
    # Desktop-only module (option does not exist on the laptop).
    features.minecraft.enable = true;
  };

  nixos.modules.laptop = {
    features.mangowc.local = true;
    features.wramp.enable = true;
  };
}
