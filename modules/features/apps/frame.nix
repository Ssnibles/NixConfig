# =============================================================================
# Frame Remote Desktop Feature
# =============================================================================
# Host-side launcher and desktop entry for the Nutanix Frame App. The client
# itself runs inside an isolated Ubuntu 24.04 Distrobox container created by
# assets/setup_frame.sh; this module only exposes a `frame` wrapper on the host
# and registers the application (and its SSO URL schemes) with the desktop.
# =============================================================================
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

      # Launch the client inside the container, forwarding any URLs (e.g. the
      # frame:// SSO callback) and audio/display through Distrobox.
      frame = pkgs.writeShellScriptBin "frame" ''
        if ! ${pkgs.distrobox}/bin/distrobox list 2>/dev/null | grep -q "| ${container} "; then
          echo "frame: Distrobox container '${container}' was not found." >&2
          echo "Run ~/NixConfig/assets/setup_frame.sh to create it." >&2
          exit 1
        fi
        exec ${pkgs.distrobox}/bin/distrobox enter ${container} -- frame "$@"
      '';

      # Install the application icon into the hicolor theme so the desktop
      # entry resolves Icon=frame.
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
        categories = [ "Network" "Utility" ];
        # Frame uses these schemes for single sign-on callbacks.
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

        # USB device redirection: the vendor rules grant access to the device
        # classes Frame forwards into a remote session. They run on the host
        # (the rootless container has no udev) and rely on the `plugdev` group.
        services.udev.extraRules = lib.mkAfter ''
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="1008", MODE="0664", GROUP="plugdev"
          SUBSYSTEMS=="usb", ATTRS{idVendor}=="1050", MODE="0664", GROUP="plugdev"
        '';
      };
    };
}
