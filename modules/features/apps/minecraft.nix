# =============================================================================
# Minecraft Applications Feature (Desktop Host)
# =============================================================================
# Java Edition through PrismLauncher (multi-instance, modded, per-instance
# Java) and Bedrock Edition through BedrockOnLinux, which runs the Windows
# GDK build under Wine with native Xbox sign-in.
# =============================================================================
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

      # Upstream only publishes `packages.<system>.default`; no overlay needed.
      bedrock =
        inputs.bedrock-on-linux.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
        environment.systemPackages = [
          # Java Edition: manages its own instances and can fetch its own
          # runtimes, but ship a JDK for server jars and manual launches.
          pkgs.prismlauncher
          pkgs.temurin-bin-21

          # Bedrock Edition (Windows GDK under Wine).
          bedrock
        ];
      };
    };
}
