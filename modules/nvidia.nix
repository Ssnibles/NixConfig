# =============================================================================
# NVIDIA Driver Module
# =============================================================================
# Configures proprietary NVIDIA drivers for systems with dedicated GPUs.
# Only activates when hostProfile.hasNvidia = true.
# Uses stable kernel and drivers for maximum compatibility.
#
# Important Notes:
#   - NVIDIA drivers are pinned to stable channel to avoid breakage
#   - Kernel modules must match kernel version exactly
#   - Wayland requires specific environment variables for NVIDIA
#   - DRM modesetting must be enabled for Wayland support
# =============================================================================
{
  pkgs,
  lib,
  stablePkgs,
  hostProfile,
  ...
}:
lib.mkIf hostProfile.hasNvidia {
  # Use stable kernel for NVIDIA driver compatibility
  boot.kernelPackages = stablePkgs.linuxPackages;

  # Blacklist nouveau (open-source NVIDIA driver) to prevent conflicts
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Load NVIDIA kernel modules at boot
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # Kernel parameters for NVIDIA Wayland support
  boot.kernelParams = [
    "nvidia-drm.modeset=1" # Enable DRM modesetting
    "nvidia-drm.fbdev=1" # Enable framebuffer device
  ];

  # X11 video driver (still needed for some compatibility)
  services.xserver.videoDrivers = [ "nvidia" ];

  # NVIDIA hardware configuration
  hardware.nvidia = {
    # Use proprietary drivers (not nouveau)
    open = false;
    # Enable modesetting for Wayland
    modesetting.enable = true;
    # Power management features
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    # Install nvidia-settings GUI
    nvidiaSettings = true;
    # Driver package from stable channel
    package = stablePkgs.linuxPackages.nvidiaPackages.stable;
  };

  # Graphics acceleration configuration
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # For Steam and some games
    extraPackages = with pkgs; [
      nvidia-vaapi-driver # Hardware video decoding
      vulkan-validation-layers # Vulkan development
    ];
  };

  # Environment variables for NVIDIA Wayland support
  environment.sessionVariables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1"; # wlroots compatibility
    __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
  };
}
