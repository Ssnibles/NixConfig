# WRAMP toolchain in Distrobox.
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
      cfg = config.features.wramp;

      container = "wramp";

      # Run each WRAMP tool inside the container.
      wramp-tools = [
        "wasm"
        "wlink"
        "wobj"
        "wcc"
        "remote"
        "trim"
      ];

      check_container = ''
        if ! ${pkgs.distrobox}/bin/distrobox list 2>/dev/null | grep -q "| ${container} "; then
          echo "wramp: Distrobox container '${container}' was not found." >&2
          echo "Run ~/NixConfig/assets/setup_wramp.sh to create it." >&2
          exit 1
        fi
      '';

      tool-wrapper =
        tool:
        pkgs.writeShellScriptBin tool ''
          ${check_container}
          exec ${pkgs.distrobox}/bin/distrobox enter ${container} -- ${tool} "$@"
        '';

      wsim-script = pkgs.writeShellScriptBin "wsim" ''
        ${check_container}
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
        ]
        ++ map tool-wrapper wramp-tools;
      };
    };
}
