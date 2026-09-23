# =============================================================================
# Podman Container & Virtualization Feature
# =============================================================================
# OCI container virtualization stack, Docker CLI alias wrapper, and Distrobox.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.podman-vm;
    in
    {
      options.features.podman-vm.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the Podman container and virtualization stack with Distrobox.";
      };

      config = lib.mkIf cfg.enable {
        virtualisation = {
          containers.enable = true;

          podman = {
            enable = true;
            dockerCompat = true;
          };
        };

        environment.systemPackages = with pkgs; [
          podman-compose
          distrobox
        ];

        # Disable auto-starting podman daemon and root system socket on boot
        systemd.services.podman.wantedBy = lib.mkForce [ ];
        systemd.sockets.podman.wantedBy = lib.mkForce [ ];
      };
    };
}