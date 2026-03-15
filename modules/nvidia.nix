# NVIDIA proprietary driver stack.
# Only applied when hostProfile.hasNvidia = true (set in flake.nix / mkHost).
#
# Both the kernel and the driver are sourced from stablePkgs (nixos-25.05)
# so the out-of-tree .ko is always compiled against the correct kernel headers.
# stablePkgs is injected via specialArgs in flake.nix.
{
  pkgs,
  lib,
  stablePkgs,
  hostProfile,
  ...
}:

lib.mkIf hostProfile.hasNvidia {

  # Use the stable LTS kernel — must match the driver below.
  # This overrides the lib.mkDefault in configuration.nix.
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

  # Tell the display stack to use the nvidia driver.
  # Required even on Wayland — without this the driver won't bind.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    nvidiaSettings = true;
    # Driver package must come from the same nixpkgs as the kernel above.
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
    # Helps the GBM backend locate the nvidia gbm library
    __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
  };
}
