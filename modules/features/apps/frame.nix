# Frame remote desktop.
# The client runs in a Distrobox container. This module provides the launcher
# and desktop entry.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.frame;

      container = "frame";

      # Run the client in the container and pass through URLs.
      frame = pkgs.writeShellScriptBin "frame" ''
        if ! ${pkgs.distrobox}/bin/distrobox list 2>/dev/null | grep -q "| ${container} "; then
          echo "frame: Distrobox container '${container}' was not found." >&2
          echo "Run ~/NixConfig/assets/setup_frame.sh to create it." >&2
          exit 1
        fi
        exec ${pkgs.distrobox}/bin/distrobox enter ${container} -- frame "$@"
      '';

      # Add the icon to the hicolor theme for the desktop entry.
      frame-icon = pkgs.runCommand "frame-icon" { } ''
        install -Dm644 ${../../../assets/frame.svg} \
          $out/share/icons/hicolor/scalable/apps/frame.svg
      '';

      frame-desktop = pkgs.makeDesktopItem {
        name = "frame";
        desktopName = "Frame";
        genericName = "Frame";
        comment = "Nutanix Frame remote desktop client";
        exec = "frame %U";
        icon = "frame";
        categories = [
          "Network"
          "Utility"
        ];
        # Single sign-on callback schemes.
        mimeTypes = [
          "x-scheme-handler/frame"
          "x-scheme-handler/frameapp"
        ];
        startupNotify = true;
      };
    in
    {
      options.features.frame.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Frame remote desktop client launcher and desktop entry.";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          frame
          frame-icon
          frame-desktop
        ];

        # The container has no udev, so the rules run on the host and rely on
        # the plugdev group.
        services.udev.extraRules = lib.mkAfter ''
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="1008", MODE="0664", GROUP="plugdev"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", MODE="0664", GROUP="plugdev"
        '';
      };
    };
}
