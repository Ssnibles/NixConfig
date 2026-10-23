# Minecraft on the desktop.
# Java Edition uses PrismLauncher. Bedrock Edition uses BedrockOnLinux.
{ inputs, ... }:
{
  nixos.modules.desktop =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      cfg = config.features.minecraft;

      # BedrockOnLinux only publishes a default package.
      bedrock = inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      options.features.minecraft = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Minecraft Java (PrismLauncher) and Bedrock (BedrockOnLinux).";
        };
      };

      config = lib.mkIf cfg.enable {
        # Minecraft 26.3 ships SDL3 (libSDL3.so from lwjgl-sdl) and dlopens the
        # Wayland client libraries at runtime. nixpkgs' modrinth-app wrapper
        # only provides the X11/GL set, so with SDL_VIDEO_DRIVER=wayland from
        # the compositor module the game dies on startup with:
        #   IllegalStateException: Unable to initialize SDL: wayland not available
        # PrismLauncher's wrapper already includes these, which is why the same
        # instance launches fine from Prism.
        nixpkgs.overlays = [
          (final: prev: {
            modrinth-app = prev.modrinth-app.overrideAttrs (old: {
              runtimeDependencies =
                "${old.runtimeDependencies}:${
                  final.lib.makeLibraryPath [
                    final.wayland
                    final.libdecor
                    final.libxkbcommon
                    # The bundled Zulu JRE's libawt_xawt.so dlopens these; without
                    # them java.awt.Toolkit/ImageIO fail and resource reload dies
                    # with a black screen. SDL3's X11 backend wants the same set.
                    final.libXi
                    final.libXrender
                    final.libXtst
                    final.libXfixes
                    final.libXScrnSaver
                  ]
                }";
            });
          })
        ];

        environment.systemPackages = [
          # PrismLauncher fetches its own runtimes. A JDK is still useful for
          # server jars and manual launches.
          pkgs.prismlauncher
          pkgs.modrinth-app
          pkgs.temurin-bin-21

          # Bedrock Edition through Wine.
          bedrock
        ];
      };
    };
}
