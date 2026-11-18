# Minecraft. Hosts that want it enable features.minecraft.
# Java Edition uses PrismLauncher. Bedrock Edition uses BedrockOnLinux.
{ inputs, ... }:
{
  flake.nixosModules.shared =
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

      # Modrinth App releases often, so tracking unstable means rebuilding it on
      # most updates. The stable build comes from cache.nixos.org, and only the
      # wrapper below is rebuilt locally.
      #
      # Minecraft 26.3 ships SDL3 (libSDL3.so from lwjgl-sdl) and dlopens the
      # Wayland client libraries at runtime. nixpkgs' wrapper only provides the
      # X11/GL set, so with SDL_VIDEO_DRIVER=wayland from the compositor module
      # the game dies on startup with:
      #   IllegalStateException: Unable to initialize SDL: wayland not available
      # PrismLauncher's wrapper already includes these, which is why the same
      # instance launches fine from Prism.
      modrinth-app = pkgs.stable.modrinth-app.overrideAttrs (old: {
        runtimeDependencies = "${old.runtimeDependencies}:${
          pkgs.stable.lib.makeLibraryPath [
            pkgs.stable.wayland
            pkgs.stable.libdecor
            pkgs.stable.libxkbcommon
            # The bundled Zulu JRE's libawt_xawt.so dlopens these; without them
            # java.awt.Toolkit/ImageIO fail and resource reload dies with a black
            # screen. SDL3's X11 backend wants the same set.
            pkgs.stable.libXi
            pkgs.stable.libXrender
            pkgs.stable.libXtst
            pkgs.stable.libXfixes
            pkgs.stable.libXScrnSaver
          ]
        }";
      });
    in
    {
      options.features.minecraft.enable = lib.mkEnableOption "Minecraft Java (PrismLauncher) and Bedrock (BedrockOnLinux)";

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          # PrismLauncher fetches its own runtimes. A JDK is still useful for
          # server jars and manual launches.
          pkgs.prismlauncher
          modrinth-app
          pkgs.temurin-bin-21

          # Bedrock Edition through Wine.
          bedrock
        ];
      };
    };
}
