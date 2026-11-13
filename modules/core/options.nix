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
          type = lib.types.enum (
            builtins.attrNames (
              lib.filterAttrs (_: type: type == "regular") (builtins.readDir ../../assets/wallpapers)
            )
          );
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

      # Hosts set this themselves. The neutral default means a host that has
      # not been classified yet gets no role-specific behaviour.
      options.nixos.hostRole = lib.mkOption {
        type = lib.types.str;
        default = "generic";
        description = "Host role, used by shared modules that need host-specific behaviour.";
      };

      options.nixos.journalNoisePatterns = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "Ignoring duplicate name"
          "gkr-pam: unable to locate daemon control file"
          "bluetoothd.*Failed to set"
          "i2c_hid_acpi.*incomplete report"
          "graphical-session.target"
          "wayland-session.target"
          "systemd-coredump.*vicinae"
        ];
        description = ''
          Regexes for known harmless journal messages. Used for systemd
          LogFilterPatterns and the boot error notification.
        '';
      };

      # Shared defaults for all hosts. Per host overrides are at the bottom.
      config = lib.mapAttrsRecursive (_: lib.mkDefault) {
        features = {
          # Compositor choice differs per host, so these are only defaults.
          hyprland.enable = false;
          mangowc.enable = true;
          niri.enable = false;
          quickshell.enable = true;
          vicinae.enable = true;
          shikane.enable = true;

          # The browser is chosen by whichever one below sets defaultBrowser.
          # Helium wins if both are enabled.
          default-apps.enable = true;

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

          spotify.enable = true;
          frame.enable = true;
          hermes.enable = false;
          wramp.enable = false;
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
}
