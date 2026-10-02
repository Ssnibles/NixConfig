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

      # "Mango" (the plain login-screen entry) is always the pinned upstream
      # input, so a known-good remote build stays available while iterating.
      # The local development input (git+file:///home/josh/mango) powers the
      # separate "Mango Local" entry, exposed only when features.mangowc.local
      # is enabled. Note: the programs.mango module itself is imported
      # unconditionally — the two inputs ship the same module — only the package
      # source differs.
      #
      # Temporary workaround for broken borders on NVIDIA proprietary drivers
      # (https://github.com/wlrfx/scenefx/pull/177). The patched scenefx is
      # threaded into both builds below so it keeps working for both inputs;
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

      mango-remote =
        (inputs.mangowc.packages.${pkgs.stdenv.hostPlatform.system}.default)
        .override {
          inherit scenefx;
        };

      # Local development build from the checked-in input, only evaluated when
      # features.mangowc.local is on.
      mango-local-base =
        (inputs.mangowc-local.packages.${pkgs.stdenv.hostPlatform.system}.default)
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
        paths = [ mango-local-base ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrap_mango() {
            local bin="$1"
            rm "$out/bin/$bin"
            makeWrapper ${mango-local-base}/bin/$bin "$out/bin/$bin" \
              --run 'if [ -x /home/${config.username}/mango/result/bin/'"$bin"' ]; then exec /home/${config.username}/mango/result/bin/'"$bin"' "$@"; fi
                     echo "[mango-dev] $(date +%Y-%m-%d_%H:%M:%S) local build missing, using packaged '"$bin"'" >> "''${XDG_CACHE_HOME:-$HOME/.cache}/mango-dev.log"'
          }
          wrap_mango mango
          if [ -f "$out/bin/mmsg" ]; then
            wrap_mango mmsg
          fi
        '';
        meta.mainProgram = "mango";
      };

      # A second, independent login-screen entry ("Mango Local"). The upstream
      # package only ships `mango.desktop`, which points at whatever is in
      # environment.systemPackages; this one hard-codes the dev wrapper and
      # prepends its bin dir so `mmsg` etc. also come from the local build.
      # providedSessions is required by services.displayManager.sessionPackages.
      mango-local-session =
        (pkgs.runCommand "mango-local-session" { } ''
          mkdir -p $out/bin $out/share/wayland-sessions

          cat > $out/bin/mango-local <<'EOF'
          #!${pkgs.runtimeShell}
          export PATH=${mango-dev}/bin:$PATH
          exec ${mango-dev}/bin/mango "$@"
          EOF
          chmod +x $out/bin/mango-local

          cat > $out/share/wayland-sessions/mango-local.desktop <<EOF
          [Desktop Entry]
          Name=Mango Local
          Comment=Mango compositor (local development build)
          Exec=$out/bin/mango-local
          TryExec=$out/bin/mango-local
          Icon=mango
          DesktopNames=mango;wlroots
          Type=Application
          EOF
        '')
        // {
          providedSessions = [ "mango-local" ];
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
        description = ''
          Add a second "Mango Local" login-screen session built from the local
          path input and wrapped to prefer ~/mango/result. The regular "Mango"
          session keeps using the pinned upstream package.
        '';
      };

      config = lib.mkIf cfg.enable {
        wallpaper-destinations = [ "Pictures/wallpaper" ];

        programs.mango.enable = true;

        # The plain "Mango" session always uses the pinned upstream package. The
        # dev wrapper is exposed as the separate "Mango Local" session below.
        programs.mango.package = mango-remote;

        # Adds share/wayland-sessions/mango-local.desktop (picked up by ly and
        # other display managers) on top of the upstream mango.desktop session.
        services.displayManager.sessionPackages =
          lib.mkIf cfg.local [ mango-local-session ];

        nixos.liveLinks = {
          "mango-config" = {
            source = "${config.nixos.configRepo}/modules/features/desktop-env/mangowc/config.conf";
            target = ".config/mango/config.conf";
          };
          "mango-binds" = {
            source = "${config.nixos.configRepo}/modules/features/desktop-env/mangowc/binds.conf";
            target = ".config/mango/binds.conf";
          };
          "mango-screenshot" = {
            source = "${config.nixos.configRepo}/modules/features/desktop-env/mangowc/screenshot.sh";
            target = ".config/mango/screenshot.sh";
          };
        };

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
