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
      ...
    }:
    {
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
        boxbuddy
      ];

      # Disable auto-starting podman daemon and root system socket on boot
      systemd.services.podman.wantedBy = lib.mkForce [ ];
      systemd.sockets.podman.wantedBy = lib.mkForce [ ];
    };
}
