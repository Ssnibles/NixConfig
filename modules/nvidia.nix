# =============================================================================
# NVIDIA Driver Module
# =============================================================================
# Configures proprietary NVIDIA drivers.
# Only activates when hostProfile.hasNvidia = true.
# Uses stable kernel and drivers for maximum compatibility.
# =============================================================================
{
  pkgs,
  lib,
  stablePkgs,
  hostProfile,
  ...
}:
lib.mkIf hostProfile.hasNvidia {
  boot.kernelPackages = stablePkgs.linuxPackages;
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
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    package = stablePkgs.linuxPackages.nvidiaPackages.stable;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      vulkan-validation-layers
    ];
  };

  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
    __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
  };
}
