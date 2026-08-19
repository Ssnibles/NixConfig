# =============================================================================
# AMD Vivado EDA Distrobox Feature
# =============================================================================
# Distrobox launcher script and desktop entry for running AMD Vivado FPGA design suite.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, config, ... }:
    let
      vivado-script = pkgs.writeShellScriptBin "vivado" ''
        exec ${pkgs.distrobox}/bin/distrobox enter arch-vivado -- vivado "$@"
      '';

      vivado-desktop = pkgs.makeDesktopItem {
        name = "vivado";
        desktopName = "Vivado 2024.2";
        exec = "vivado";
        icon = "vivado";
        categories = [ "Development" ];
        terminal = false;
      };
    in
    {
      environment.systemPackages = [
        vivado-script
        vivado-desktop
      ];
    };
}
