# Shared helpers injected as module arguments.
{ lib, ... }:
{
  flake.lib.mkSingleScript =
    pkgs:
    {
      name,
      file,
      src,
      program,
      description,
      interpreter ? pkgs.bash,
      license ? lib.licenses.mit,
    }:
    pkgs.stdenvNoCC.mkDerivation {
      pname = name;
      version = "0.1.0";
      inherit src;
      dontConfigure = true;
      dontBuild = true;

      installPhase = ''
        runHook preInstall
        install -Dm755 ${file} $out/bin/${name}
        substituteInPlace $out/bin/${name} \
          --replace-fail "#!/usr/bin/env ${program}" "#!${interpreter}/bin/${program}"
        runHook postInstall
      '';

      meta = {
        inherit description license;
        mainProgram = name;
      };
    };

  nixos.modules.shared =
    { config, pkgs, ... }:
    {
      # Run a tool inside a Distrobox container, failing with setup advice when
      # the container has not been created yet.
      _module.args.mkDistroboxTool =
        {
          container,
          setupScript,
          name,
          command ? name,
        }:
        pkgs.writeShellScriptBin name ''
          if ! ${pkgs.distrobox}/bin/distrobox list 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q "| ${container} "; then
            echo "${name}: Distrobox container '${container}' was not found." >&2
            echo "Run ${setupScript} to create it." >&2
            exit 1
          fi
          exec ${pkgs.distrobox}/bin/distrobox enter ${container} -- ${command} "$@"
        '';

      # Build a user service that follows the graphical session. Services that
      # need the system profile add their own tools through `path`.
      _module.args.mkWaylandService =
        {
          description,
          execStart,
          path ? [ ],
          type ? "simple",
          restart ? "on-failure",
          restartSec ? 2,
        }:
        {
          inherit description;
          wantedBy = [ "wayland-session.target" ];
          after = [ "wayland-session.target" ];
          partOf = [ "wayland-session.target" ];
          path = [ config.system.path ] ++ path;
          unitConfig = {
            # Restart forever for long-lived session daemons.
            StartLimitBurst = 0;
            StartLimitIntervalSec = 0;
          };
          serviceConfig = {
            Type = type;
            ExecStart = execStart;
            Restart = restart;
            RestartSec = restartSec;
          };
        };
    };
}
