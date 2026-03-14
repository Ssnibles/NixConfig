{ config, pkgs, lib, ... }:

# ===========================================================================
# NVIDIA — proprietary driver configuration
#
# This module is imported unconditionally from configuration.nix, but every
# option inside is wrapped in `lib.mkIf config.hostProfile.hasNvidia` so
# nothing is applied on machines without an Nvidia GPU (e.g. the AMD APU
# laptop). This avoids the infinite-recursion error that occurs when you
# try to gate an import on a config value.
#
# Targets RTX 3000-series (Ampere) and newer with the proprietary driver.
#
# Key decisions:
#   open = false              — proprietary driver; the open kernel module
#                               isn't mature enough for daily Wayland use yet
#   modesetting.enable = true — required for Wayland/Hyprland; lets the
#                               compositor drive the display via DRM directly
#   powerManagement = true    — enables nvidia-suspend/resume/hibernate
#                               services; without this the GPU loses state
#                               after sleep and the system hangs on resume
#
# boot.kernelParams:
#   nvidia-drm.modeset=1  — enables DRM modesetting at the kernel level
#   nvidia-drm.fbdev=1    — enables the Nvidia fbdev driver so the kernel
#                           framebuffer works correctly (needed for ly,
#                           TTY rendering, and early boot graphics)
# ===========================================================================

{
  config = lib.mkIf config.hostProfile.hasNvidia {

    # Load the Nvidia proprietary kernel modules early so modesetting is
    # active before the display manager starts.
    boot.initrd.kernelModules = [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    boot.kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];

    hardware.nvidia = {
      # Proprietary driver — better Wayland/Vulkan support than the open
      # kernel module at this point in time.
      open = false;

      # Stable branch. Switch to nvidiaPackages.beta if you need fixes
      # or features not yet in stable.
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      # Required for Wayland compositors (Hyprland, sway, etc.) to drive
      # the display directly via DRM rather than going through X.
      modesetting.enable = true;

      # Enables nvidia-suspend.service, nvidia-resume.service, and
      # nvidia-hibernate.service. Without this, GPU state is lost on sleep
      # and the system either hangs on resume or corrupts the display.
      powerManagement.enable = true;

      # Fine-grained power management puts the GPU into a lower-power state
      # when idle. Safe on Ampere (RTX 3000) and newer, but can cause
      # flickering on some cards — disable if you see GPU resets.
      powerManagement.finegrained = false;

      # nvidia-settings GUI — useful for checking driver version, connector
      # info, and clock offsets without dropping to the terminal.
      nvidiaSettings = true;
    };

    # OpenGL / Vulkan + hardware video decode.
    # Required for Wayland, Vulkan applications, and GPU-accelerated video.
    hardware.graphics = {
      enable = true;
      enable32Bit = true; # needed for Steam / 32-bit Vulkan apps
      extraPackages = with pkgs; [
        # VA-API backend for Nvidia (hardware video decode in Firefox, mpv, etc.)
        nvidia-vaapi-driver
        # Vulkan validation layers — useful for debugging, harmless in prod
        vulkan-validation-layers
      ];
    };

    # Tell Wayland/EGL to use the Nvidia driver rather than the Mesa software
    # fallback. Without this some apps (wlroots compositors, Electron apps)
    # silently fall back to llvmpipe.
    environment.sessionVariables = {
      GBM_BACKEND = "nvidia-drm";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      # Uncomment if you see cursor flickering in Hyprland:
      WLR_NO_HARDWARE_CURSORS = "1";
    };

  }; # end mkIf hasNvidia
}

