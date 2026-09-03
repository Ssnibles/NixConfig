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
      ...
    }:
    {
      # Pin standard Linux kernel for NVIDIA driver compatibility
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
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
        package = pkgs.linuxPackages.nvidiaPackages.stable;
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
      };
    };
}
