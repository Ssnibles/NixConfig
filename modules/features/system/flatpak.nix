# =============================================================================
# System Flatpak Feature
# =============================================================================
# Declarative Flatpak support via the nix-flatpak module (gmodena). NixOS'
# built-in services.flatpak only knows `enable`; nix-flatpak adds the
# declarative `remotes` and `packages` options used below.
#
# Nuvio Desktop is NOT published on Flathub, so it is installed from a
# version-pinned GitHub release `.flatpak` bundle. Sober is pulled from Flathub.
# =============================================================================
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
    { pkgs, lib, config, ... }:
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
        };
      };
    };
}
