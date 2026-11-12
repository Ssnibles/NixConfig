# WRAMP toolchain in Distrobox.
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      mkDistroboxTool,
      ...
    }:
    let
      cfg = config.features.wramp;

      container = "wramp";
      setupScript = "~/NixConfig/assets/setup_wramp.sh";

      # Run each WRAMP tool inside the container. wsim launches the simulator.
      wramp-tools = [
        "wasm"
        "wlink"
        "wobj"
        "wcc"
        "remote"
        "trim"
        "wsim"
      ];

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
      options.features.wramp.enable = lib.mkEnableOption "the WRAMP toolchain and wsim simulator Distrobox launchers";

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          wsim-desktop
        ]
        ++ map (name: mkDistroboxTool { inherit container setupScript name; }) wramp-tools;
      };
    };
}
