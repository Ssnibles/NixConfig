# Mango Wayland compositor.
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
      inherit (config.theme.colours)
        accent
        border
        ;

      # Mango is the pinned upstream session. Mango Local is built from the
      # local checkout and only exposed when features.mangowc.local is on.
      #
      # The scenefx patch fixes broken borders on the NVIDIA driver. Remove it
      # when the upstream fix is released.
      scenefx =
        inputs.scenefx.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
          (oldAttrs: {
            postPatch = (oldAttrs.postPatch or "") + ''
              substituteInPlace render/egl.c \
                --replace-fail 'attribs[atti++] = 2;' 'attribs[atti++] = 3;'
              substituteInPlace render/fx_renderer/shaders.c \
                --replace-fail 'glShaderSource(shader, 1, &src, NULL);' \
                  'const char *prefix = (type == GL_FRAGMENT_SHADER) ? "#ifndef GL_FRAGMENT_PRECISION_HIGH\n#define GL_FRAGMENT_PRECISION_HIGH 1\n#endif\n" : ""; const GLchar *sources[] = { prefix, src }; glShaderSource(shader, 2, sources, NULL);'
            '';
          });

      mango-remote = inputs.mangowc.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
        inherit scenefx;
      };

      # Local development build from the checked-in input.
      mango-local-base =
        inputs.mangowc-local.packages.${pkgs.stdenv.hostPlatform.system}.default.override
          {
            inherit scenefx;
          };

      # Prefer a freshly built binary in ~/mango/result at runtime, so a local
      # change only needs nix build and a session restart. Fall back to the
      # packaged binary and log when no local build is present.
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
                     mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}"
                     echo "[mango-dev] $(date +%Y-%m-%d_%H:%M:%S) local build missing, using packaged '"$bin"'" >> "''${XDG_CACHE_HOME:-$HOME/.cache}/mango-dev.log"'
          }
          wrap_mango mango
          if [ -f "$out/bin/mmsg" ]; then
            wrap_mango mmsg
          fi
        '';
        meta.mainProgram = "mango";
      };

      # A separate login entry for Mango Local. It runs the dev wrapper and
      # puts its bin directory first so mmsg also comes from the local build.
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

      # Vesktop opens three portal sessions for one share. Cache the choice for
      # a short time so the picker only appears once, unless the source list
      # changes.
      screencast-chooser = pkgs.writeShellScript "wlr-screencast-chooser" ''
        cache="''${XDG_RUNTIME_DIR:-/tmp}/wlr-screencast-choice"
        input=$(${pkgs.coreutils}/bin/cat)

        if [ -f "$cache" ] && [ -n "$(${pkgs.findutils}/bin/find "$cache" -newermt '-30 seconds' 2>/dev/null)" ]; then
          cached=$(${pkgs.coreutils}/bin/cat "$cache")
          if printf '%s\n' "$input" | ${pkgs.gnugrep}/bin/grep -qxF -- "$cached"; then
            printf '%s\n' "$cached"
            exit 0
          fi
        fi

        choice=$(printf '%s\n' "$input" | ${pkgs.unstable.vicinae}/bin/vicinae dmenu -f data -n 'Share screen' -p 'Pick a screen or window')
        if [ -n "$choice" ]; then
          printf '%s\n' "$choice" > "$cache"
          printf '%s\n' "$choice"
        fi
      '';
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

        # The upstream mango module enables xdg-desktop-portal-wlr but leaves
        # its settings empty. NixOS always passes its own config file, so the
        # default chooser fails and Vesktop cannot share a screen. Use Vicinae
        # as the chooser. It can pick a monitor or a window.
        xdg.portal.wlr.settings.screencast = {
          chooser_type = "dmenu";
          # Vesktop opens three sessions per share, so cache the choice.
          chooser_cmd = "${screencast-chooser}";
        };

        environment.sessionVariables.SDL_VIDEO_DRIVER = "wayland";

        programs.mango.enable = true;

        # The normal Mango session keeps the pinned upstream package.
        programs.mango.package = mango-remote;

        # Adds mango-local.desktop to the login screen.
        services.displayManager.sessionPackages = lib.mkIf cfg.local [ mango-local-session ];

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
                focus_color = 0x${accent}ff
                border_color = 0x${border}ff
              '';
            };
          };
        };
      };
    };
}
