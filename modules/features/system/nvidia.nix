# NVIDIA GPU setup. Hosts with an NVIDIA card enable features.nvidia.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      cfg = config.features.nvidia;
    in
    {
      options.features.nvidia.enable = lib.mkEnableOption "the NVIDIA proprietary driver";

      config = lib.mkIf cfg.enable {
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

        hardware.graphics.extraPackages = with pkgs; [
          nvidia-vaapi-driver
        ];

        # Wayland and VA-API environment for NVIDIA.
        environment.sessionVariables = {
          # Use the NVIDIA drivers for GLX and video decoding.
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";

          # NVIDIA's EGL explicit-fence sync breaks WebKitGTK's DMA-BUF
          # compositing: it either segfaults in WebKit::AcceleratedBackingStore
          # or stalls for a frame or more at a time. Work around it at the driver
          # level so WebKit keeps full GPU compositing.
          #
          # Do NOT set WEBKIT_DISABLE_DMABUF_RENDERER=1 here: it stops the
          # crashes, but on WebKit 2.44+ it forces a much slower rendering path
          # and is what makes apps like the Modrinth App feel laggy. Likewise
          # never set WEBKIT_DISABLE_COMPOSITING_MODE, which is pure CPU
          # rendering. If one specific WebKit app still renders blank or crashes,
          # set WEBKIT_DISABLE_DMABUF_RENDERER=1 for that app only (wrapper or
          # Flatpak override), not for the whole session.
          __NV_DISABLE_EXPLICIT_SYNC = "1";
        };
      };
    };
}
