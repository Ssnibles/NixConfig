# =============================================================================
# Mango Wayland Compositor Feature
# =============================================================================
# Enables Mango Wayland compositor, links config & keybindings, and generates
# theme colors file via Hjem.
# =============================================================================
{ ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      inputs,
      ...
    }:
    let
      cfg = config.features.mangowc;
      inherit (config.theme.colors)
        accent
        border
        ;

      # Uses the pinned upstream input by default, or the local development
      # input (path:/home/josh/mango) when features.mangowc.local is enabled.
      # Note: the programs.mango module itself is imported unconditionally — the
      # two inputs ship the same module — only the package source differs.
      #
      # Temporary workaround for broken borders on NVIDIA proprietary drivers
      # (https://github.com/wlrfx/scenefx/pull/177). The patched scenefx is
      # threaded into the mango build below so it keeps working for both inputs;
      # drop this once upstream merges/releases the fix.
      scenefx = inputs.scenefx.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (oldAttrs: {
        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace render/egl.c \
            --replace-fail 'attribs[atti++] = 2;' 'attribs[atti++] = 3;'
          substituteInPlace render/fx_renderer/shaders.c \
            --replace-fail 'glShaderSource(shader, 1, &src, NULL);' \
              'const char *prefix = (type == GL_FRAGMENT_SHADER) ? "#ifndef GL_FRAGMENT_PRECISION_HIGH\n#define GL_FRAGMENT_PRECISION_HIGH 1\n#endif\n" : ""; const GLchar *sources[] = { prefix, src }; glShaderSource(shader, 2, sources, NULL);'
        '';
      });

      mango-base =
        ((if cfg.local then inputs.mangowc-local else inputs.mangowc)
          .packages.${pkgs.stdenv.hostPlatform.system}.default)
        .override {
          inherit scenefx;
        };

      # Development wrapper: at runtime it prefers a freshly built binary from
      # /home/${config.username}/mango/result, so local changes can be tested
      # with just `nix build` in ~/mango followed by a session restart, without
      # a full nixos-rebuild. If no local build is present it falls back to the
      # packaged binary and logs the fallback so it is never silent.
      mango-dev = pkgs.symlinkJoin {
        name = "mango-dev";
        paths = [ mango-base ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrap_mango() {
            local bin="$1"
            rm "$out/bin/$bin"
            makeWrapper ${mango-base}/bin/$bin "$out/bin/$bin" \
              --run 'if [ -x /home/${config.username}/mango/result/bin/'"$bin"' ]; then exec /home/${config.username}/mango/result/bin/'"$bin"' "$@"; fi
                     echo "[mango-dev] $(date +%Y-%m-%d_%H:%M:%S) local build missing, using packaged '"$bin"'" >> "''${XDG_CACHE_HOME:-$HOME/.cache}/mango-dev.log"'
          }
          wrap_mango mango
          if [ -f "$out/bin/mmsg" ]; then
            wrap_mango mmsg
          fi
        '';
        meta.mainProgram = "mango";
        passthru = (mango-base.passthru or { }) // {
          inherit (mango-base) providedSessions;
        };
      };
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

      options.features.mangowc.local = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Build from the local path input and wrap binaries to prefer ~/mango/result.";
      };

      config = lib.mkIf cfg.enable {
        wallpaper-destinations = [ "Pictures/wallpaper" ];

        programs.mango.enable = true;

        # The upstream package ships its binaries as-is; the dev wrapper is only
        # used when iterating on the local input.
        programs.mango.package =
          if cfg.local then mango-dev else mango-base;

        system.activationScripts.mango-config = ''
          mkdir -p /home/${config.username}/.config/mango
          chown -R ${config.username}:users /home/${config.username}/.config/mango
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/mangowc/config.conf /home/${config.username}/.config/mango/config.conf
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/mangowc/binds.conf /home/${config.username}/.config/mango/binds.conf
          ln -sfn /home/${config.username}/NixConfig/modules/features/desktop-env/mangowc/screenshot.sh /home/${config.username}/.config/mango/screenshot.sh
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
