# =============================================================================
# NVIDIA Driver Module
# =============================================================================
# Configures proprietary NVIDIA drivers for hosts with hasNvidia = true.
# This module is conditionally included via lib/mkHost.nix when hasNvidia flag
# is set for a host configuration.
#
# Key Design Decisions:
#   • Uses STABLE kernel/drivers to prevent module version mismatches
#     (common.nix defaults to latest kernel, this overrides to stable)
#   • Enables DRM modesetting + fbdev for full Wayland compositor support
#   • Blacklists nouveau to prevent boot conflicts with proprietary driver
#   • Configures GBM/EGL environment for NVIDIA-specific rendering pipeline
#
# Compatibility:
#   • Wayland: Hyprland, Sway (requires DRM modesetting)
#   • Gaming: Steam, Lutris, Proton (32-bit support enabled)
#   • Video: Hardware-accelerated decode via nvidia-vaapi-driver
# =============================================================================
{
  pkgs,
  lib,
  hostProfile,
  ...
}:
lib.mkIf hostProfile.hasNvidia {
  # ═══════════════════════════════════════════════════════════════════════════
  # KERNEL CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  # Use stable kernel to match NVIDIA driver version
  # Overrides common.nix default (linuxPackages_latest)
  # Prevents "version magic mismatch" errors on unstable kernel updates
  boot.kernelPackages = pkgs.linuxPackages;

  # Blacklist open-source nouveau driver (conflicts with proprietary)
  # Applied at initrd stage to prevent loading during boot
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Load NVIDIA kernel modules at boot
  # nvidia_drm: DRM (Direct Rendering Manager) for Wayland modesetting
  # nvidia_modeset: Kernel modesetting support
  # nvidia_uvm: Unified Virtual Memory (CUDA, compute workloads)
  boot.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # Kernel parameters for NVIDIA Wayland support
  boot.kernelParams = [
    "nvidia-drm.modeset=1" # Enable DRM KMS (kernel modesetting) - REQUIRED for Wayland
    "nvidia-drm.fbdev=1"   # Enable fbdev emulation for compatibility with older software
  ];

  # ═══════════════════════════════════════════════════════════════════════════
  # XORG CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  # X server driver (required even for Wayland for GLX/Vulkan compat)
  # Enables: XWayland OpenGL, legacy X11 apps under Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  # ═══════════════════════════════════════════════════════════════════════════
  # NVIDIA DRIVER SETTINGS
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.nvidia = {
    # Use proprietary driver (not open-source nouveau)
    # Open-source NVIDIA kernel modules are still experimental (not ready for production)
    open = false;

    # Enable DRM kernel modesetting (required for Wayland compositors)
    modesetting.enable = true;

    # Power management: Suspend/resume support for NVIDIA GPUs
    # Prevents black screen on wake from sleep
    powerManagement = {
      enable = true;
      # Fine-grained power management: EXPERIMENTAL, can cause instability
      # Only enable for laptops with hybrid graphics (NVIDIA + integrated)
      finegrained = false;
    };

    # NVIDIA X Server Settings GUI (nvidia-settings command)
    # Useful for: overclocking, fan curves, multi-monitor setup
    nvidiaSettings = true;

    # Driver package: stable branch
    # Alternatives: beta, vulkan_beta, production (latest)
    # Stable recommended for reliability
    package = pkgs.linuxPackages.nvidiaPackages.stable;
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # GRAPHICS CONFIGURATION
  # ═══════════════════════════════════════════════════════════════════════════
  hardware.graphics = {
    enable = true;
    # 32-bit driver support (required for Steam, Wine, older games)
    enable32Bit = true;

    extraPackages = with pkgs; [
      # Hardware-accelerated video decoding (VA-API via NVDEC)
      # Enables GPU video decode in: Firefox, MPV, VLC
      nvidia-vaapi-driver

      # Vulkan validation layers (helpful for debugging graphics issues)
      vulkan-validation-layers
    ];
  };

  # ═══════════════════════════════════════════════════════════════════════════
  # WAYLAND ENVIRONMENT VARIABLES
  # ═══════════════════════════════════════════════════════════════════════════
  # NVIDIA-specific environment for Wayland compositors (Hyprland, Sway)
  environment.sessionVariables = {
    # Use NVIDIA's GBM backend (required for buffer allocation)
    GBM_BACKEND = "nvidia-drm";

    # Force NVIDIA as the GLX vendor (fixes OpenGL app rendering)
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # EGL vendor library directory (NVIDIA-specific EGL implementation)
    __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";

  };
}
