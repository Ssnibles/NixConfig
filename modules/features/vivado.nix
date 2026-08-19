{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      config,
      ...
    }:
    {
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "vivado" ''
          distrobox enter vivado -- bash -c "source /home/${config.username}/Vivado/Vivado/2024.1/settings64.sh && /home/${config.username}/Vivado/Vivado/2024.1/bin/vivado"
        '')
        (pkgs.makeDesktopItem {
          name = "vivado";
          desktopName = "Vivado 2024.1";
          comment = "AMD Vivado Design Suite";
          exec = "vivado";
          icon = "/home/${config.username}/Vivado/Vivado/2024.1/icons/vivado.png";
          categories = [
            "Development"
            "Electronics"
          ];
          mimeTypes = [ "application/x-vivado-project" ];
        })
      ];
    };
}
