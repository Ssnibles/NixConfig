# =============================================================================
# NVIDIA Driver Module
# =============================================================================
# Configures proprietary NVIDIA drivers for hosts where hasNvidia = true.
# Drivers are pinned to the stable channel to avoid breakage from unstable
# kernel/driver mismatches.
#
# Notes:
#   - Pins the entire kernel to stable so modules match the driver version
#   - DRM modesetting and fbdev must both be enabled for Wayland support
#   - nouveau is blacklisted to prevent conflicts at boot
# =============================================================================
{
  pkgs,
  lib,
  stablePkgs,
  hostProfile,
  ...
}:
lib.mkIf hostProfile.hasNvidia {
  # Pin kernel to stable for reliable driver compatibility
  boot.kernelPackages = stablePkgs.linuxPackages;

  boot.blacklistedKernelModules = [ "nouveau" ];

  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1" # Required for Wayland
    "nvidia-drm.fbdev=1" # Required for framebuffer device
  ];

  # X server driver (still needed for GLX/Vulkan compatibility paths)
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = false; # Use proprietary drivers, not nouveau
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = stablePkgs.linuxPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Steam and 32-bit games
    extraPackages = with pkgs; [
      nvidia-vaapi-driver # Hardware video decoding
      vulkan-validation-layers
    ];
  };

  # Environment variables required for NVIDIA under Wayland
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
  };
}
