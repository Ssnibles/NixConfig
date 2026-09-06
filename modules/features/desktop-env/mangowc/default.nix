# =============================================================================
# Mango Wayland Compositor Feature
# =============================================================================
# Enables Mango Wayland compositor, links config & keybindings, and generates
# theme colors file via Hjem.
# =============================================================================
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.mangowc;
      inherit (config.theme.colors)
        accent
        border
        ;
    in
    {
      imports = [
        inputs.mangowc.nixosModules.mango
      ];

      options.features.mangowc.enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable MangoWC Wayland compositor feature.";
      };

      config = lib.mkIf cfg.enable {
        wallpaper-destinations = [ "Pictures/wallpaper" ];

        programs.mango.enable = true;

        # Development wrapper: dynamically executes the local build from
        # /home/${config.username}/mango/result/bin/mango if it exists.
        # This allows rapid local development: simply run `nix build` in ~/mango,
        # and on the next session start it automatically runs the new binary
        # without needing a full `nixos-rebuild switch`.
        programs.mango.package =
          let
            mango-base = inputs.mangowc.packages.${pkgs.stdenv.hostPlatform.system}.default;
          in
          pkgs.symlinkJoin {
            name = "mango-dev";
            paths = [ mango-base ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              rm $out/bin/mango
              makeWrapper ${mango-base}/bin/mango $out/bin/mango \
                --run 'if [ -x /home/${config.username}/mango/result/bin/mango ]; then exec /home/${config.username}/mango/result/bin/mango "$@"; fi'
              if [ -f $out/bin/mmsg ]; then
                rm $out/bin/mmsg
                makeWrapper ${mango-base}/bin/mmsg $out/bin/mmsg \
                  --run 'if [ -x /home/${config.username}/mango/result/bin/mmsg ]; then exec /home/${config.username}/mango/result/bin/mmsg "$@"; fi'
              fi
            '';
            meta.mainProgram = "mango";
            passthru = (mango-base.passthru or { }) // {
              inherit (mango-base) providedSessions;
            };
          };

        system.activationScripts.mango-config = ''
          mkdir -p /home/${config.username}/.config/mango
          chown -R ${config.username}:users /home/${config.username}/.config/mango
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/mangowc/config.conf /home/${config.username}/.config/mango/config.conf
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/mangowc/binds.conf /home/${config.username}/.config/mango/binds.conf
        '';

        hjem.users."${config.username}" = {
          enable = true;
          files = {
            ".config/mango/colours.conf" = {
              text = ''
                focuscolor = 0x${accent}ff
                bordercolor = 0x${border}ff
              '';
            };
            ".config/xdg-desktop-portal-wlr/config" = {
              text = ''
                [screencast]
                chooser_type = simple
                chooser_cmd = ${pkgs.slurp}/bin/slurp -f %o -or
              '';
            };
          };
        };
      };
    };
}
