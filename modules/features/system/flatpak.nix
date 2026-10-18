# System Flatpak Feature
# Declarative Flatpak support via the nix-flatpak module (gmodena). NixOS'
# built-in services.flatpak only knows `enable`; nix-flatpak adds the
# declarative `remotes` and `packages` options used below.
#
# Nuvio Desktop is NOT published on Flathub, so it is installed from a
# version-pinned GitHub release `.flatpak` bundle. Sober is pulled from Flathub.
{ inputs, ... }:
let
  # Nuvio Desktop (https://github.com/NuvioMedia/NuvioDesktop) is alpha software
  # and publishes one bundle per release. To bump:
  #   1. set `nuvioVersion` to the new tag (e.g. "0.1.28-alpha");
  #   2. refresh `nuvioHash`:
  #        nix-prefetch-url "https://github.com/NuvioMedia/NuvioDesktop/releases/download/<v>/Nuvio-Linux-x86_64-<v>.flatpak"
  #      or take that file's sha256 from the release's SHA256SUMS.txt and run
  #        nix hash convert --hash-algo sha256 --to sri <hex>
  nuvioVersion = "0.1.27-alpha";
  nuvioHash = "sha256-iUZNxC8P1UyNKOE9TJCymuEWFkxveR5/oISsKRkm4aA=";
  nuvioUrl = "https://github.com/NuvioMedia/NuvioDesktop/releases/download/${nuvioVersion}/Nuvio-Linux-x86_64-${nuvioVersion}.flatpak";
in
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];

      options.features.flatpak.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable Flatpak with the Flathub remote and a declarative app set.";
      };

      config = lib.mkIf config.features.flatpak.enable {
        # xdg.portal.enable is set globally in base.nix, which satisfies the
        # assertion the stock Flatpak module makes.
        services.flatpak = {
          enable = true;

          remotes = [
            {
              name = "flathub";
              location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
            }
          ];

          # Sober (Roblox) has to track the live Roblox version or it stops
          # working, so Flathub apps are refreshed on a schedule. This only
          # touches remote-backed apps; the Nuvio bundle below is hash-pinned
          # and is never auto-updated. Set `auto.enable = false` for manual.
          update.auto = {
            enable = true;
            onCalendar = "daily";
          };

          packages = [
            # Roblox client for Linux (community runtime, sandboxed via Flatpak).
            "org.vinegarhq.Sober"
            "app.twintaillauncher.ttl"

            # Nuvio Desktop — not on Flathub; pinned release bundle from GitHub.
            # The bundle is uninstalled/reinstalled automatically when
            # `nuvioHash` changes, so a version bump is picked up on activation.
            {
              appId = "com.nuvio.media.desktop";
              sha256 = nuvioHash;
              bundle = "${pkgs.fetchurl {
                url = nuvioUrl;
                hash = nuvioHash;
              }}";
            }
          ];

          # Flatpak apps do not inherit environment.sessionVariables, so the
          # NVIDIA + WebKitGTK workaround has to be injected per app.
          #
          # Twintail Launcher is a Tauri app (WebKitGTK). On NVIDIA it forces
          #   WEBKIT_DISABLE_DMABUF_RENDERER=1
          #   WEBKIT_DISABLE_COMPOSITING_MODE=1   <-- the problem
          #   __NV_DISABLE_EXPLICIT_SYNC=1
          # (src-tauri/src/utils/gpu.rs). Disabling accelerated compositing
          # makes WebKit paint on the CPU: an idle window pins WebKitWebProcess
          # at ~50% CPU and the UI lags badly.
          #
          # TTL_BYPASS_NVIDIA_FIXES makes the app skip all of that; we then
          # re-apply only the half that is actually needed (disable the broken
          # DMA-BUF renderer, keep GPU compositing). The `wayland` socket is
          # added so the window does not have to round-trip through XWayland.
          #
          # If the app misbehaves on native Wayland, drop `Context.sockets`.
          # If WebKit renders blank/glitchy, remove WEBKIT_DISABLE_DMABUF_RENDERER
          # as well (upstream's workaround was overly broad; disabling the
          # DMA-BUF renderer is the documented NVIDIA fix).
          overrides = {
            "app.twintaillauncher.ttl" = {
              Context.sockets = [ "wayland" ];
              Environment = {
                TTL_BYPASS_NVIDIA_FIXES = "1";
                WEBKIT_DISABLE_DMABUF_RENDERER = "1";
              };
            };
          };
        };

        # The upstream nix-flatpak module orders the on-activation service after
        # multi-user.target, but the auto-update timer only depends on
        # timers.target. Its Persistent=true catch-up run therefore fires
        # within the first seconds of boot -- before the network is up -- and
        # fails with "Could not resolve hostname", self-healing ~60s later on
        # restart. Delay it past multi-user and express the network dependency
        # so the common case no longer logs a boot failure.
        systemd.services."flatpak-managed-install-timer" = {
          after = [
            "multi-user.target"
            "network-online.target"
          ];
          wants = [ "network-online.target" ];
        };
        systemd.services."flatpak-managed-install".wants = [ "network-online.target" ];
      };
    };
}
