# =============================================================================
# NVIDIA GPU Hardware Feature (Desktop Host)
# =============================================================================
# Proprietary NVIDIA driver configuration, DRM modesetting parameters,
# VA-API hardware decoding, and Wayland compositor environment overrides.
# =============================================================================
{ ... }:
{
  nixos.modules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      boot.blacklistedKernelModules = [ "nouveau" ];
      boot.kernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ];
      boot.kernelParams = [
        "nvidia-drm.modeset=1"
        "nvidia-drm.fbdev=1"
      ];

      services.xserver.videoDrivers = [ "nvidia" ];

      hardware.nvidia = {
        open = false;
        modesetting.enable = true;
        powerManagement = {
          enable = true;
          finegrained = false;
        };
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
      };

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
        ];
      };

      # Wayland & EGL / GBM environment variables for NVIDIA GPUs
      environment.sessionVariables = {
        # Force applications to use Wayland natively
        NIXOS_OZONE_WL = "1"; # For Chromium/Electron apps (VS Code, Discord, Slack)
        ELECTRON_OZONE_PLATFORM_HINT = "auto";
        # Keep GLX and Video Acceleration pointed to NVIDIA
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";

        # WebKitGTK (Tauri, GNOME Web, DBeaver's embedded browser) selects a
        # DMA-BUF renderer that is broken/slow on the proprietary NVIDIA
        # driver: WebKit ends up stuttering or falling back to software.
        # Disable *only* that renderer and keep GPU (EGL) compositing.
        #
        # Do NOT set WEBKIT_DISABLE_COMPOSITING_MODE: that turns off all GPU
        # compositing and makes WebKit apps paint on the CPU. Some Tauri apps
        # (e.g. Twintail Launcher) set it themselves -- see the Flatpak
        # override in system/flatpak.nix for that case.
        WEBKIT_DISABLE_DMABUF_RENDERER = "1";
      };
    };
}
