# Podman containers and virtualisation.
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
      options.features.podman-vm.enable = lib.mkEnableOption "the Podman container and virtualisation stack with Distrobox";

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

        # Podman should not start on boot. Containers are started when needed.
        systemd.services.podman.wantedBy = lib.mkForce [ ];
        systemd.sockets.podman.wantedBy = lib.mkForce [ ];
      };
    };
}
