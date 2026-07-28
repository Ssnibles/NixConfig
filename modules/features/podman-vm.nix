{ self, inputs, ... }:
{
  flake.nixosModules.podman-vm =
    {
      pkgs,
      lib,
      config,
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

      environment.systemPackages =
        with pkgs;
        [
          podman-compose
          podman-desktop
          distrobox
          boxbuddy
        ]
        ++ [
          (pkgs.writeShellScriptBin "vivado" ''
            exec distrobox enter vivado -- /home/josh/vivado-wrapper.sh "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "vivado";
            desktopName = "Vivado 2019.2";
            comment = "AMD Vivado Design Suite";
            exec = "vivado %F";
            icon = "/home/josh/Xilinx/Vivado/2019.2/doc/images/vivado_logo.png";
            categories = [ "Development" "Electronics" ];
            mimeTypes = [ "application/x-vivado-project" ];
          })
        ];

      systemd.services.podman.wantedBy = lib.mkForce [ ];
    };
}
