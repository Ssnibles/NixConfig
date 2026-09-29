# =============================================================================
# WRAMP Toolchain & Simulator Distrobox Feature
# =============================================================================
# Distrobox launcher scripts and desktop entry for the WRAMP (Waikato RISC
# Architecture MicroProcessor) toolchain and wsim simulator.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    { pkgs, lib, config, ... }:
    let
      cfg = config.features.wramp;

      container = "wramp";

      # Thin wrappers that execute a WRAMP tool inside the Distrobox container,
      # so the toolchain can be driven directly from the host (Neovim, shell).
      wramp-tools = [
        "wasm"
        "wlink"
        "wobj"
        "wcc"
        "remote"
        "trim"
      ];

      tool-wrapper = tool: pkgs.writeShellScriptBin tool ''
        exec ${pkgs.distrobox}/bin/distrobox enter ${container} -- ${tool} "$@"
      '';

      wsim-script = pkgs.writeShellScriptBin "wsim" ''
        exec ${pkgs.distrobox}/bin/distrobox enter ${container} -- wsim "$@"
      '';

      wsim-desktop = pkgs.makeDesktopItem {
        name = "wsim";
        desktopName = "WRAMP Simulator";
        comment = "Simulator for the WRAMP CPU";
        exec = "wsim";
        icon = "utilities-terminal";
        categories = [ "Development" ];
        terminal = false;
      };
    in
    {
      options.features.wramp.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable the WRAMP toolchain and wsim simulator Distrobox launchers.";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          wsim-script
          wsim-desktop
        ] ++ map tool-wrapper wramp-tools;
      };
    };
}
