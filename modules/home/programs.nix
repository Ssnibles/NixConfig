# =============================================================================
# Miscellaneous Program Configuration
# =============================================================================
# Configured Home Manager programs that don't warrant their own file.
# Currently: spotify-player (TUI client) and Java runtime.
# =============================================================================
{
  config,
  lib,
  ...
}:
let
  spotifyIdFile = ../../secrets/spotify-id.age;
  spotifySecretFile = ../../secrets/spotify-secret.age;
  spotifySecretsAvailable =
    builtins.pathExists spotifyIdFile && builtins.pathExists spotifySecretFile;
in
{
  # Spotify Player (TUI client)
  programs.spotify-player = {
    enable = spotifySecretsAvailable;
    settings = {
      # Credentials are provisioned by agenix at runtime.
      client_id_command = "cat /run/agenix/spotify-id";
      client_secret_command = "cat /run/agenix/spotify-secret";
      device = {
        name = "Terminal";
        device_type = "computer";
      };
    };
  };

  warnings = lib.optional (!spotifySecretsAvailable) ''
    Spotify credentials are not configured.
    Add secrets/spotify-id.age and secrets/spotify-secret.age to enable spotify-player.
  '';

  # Direnv (Nix integration for shell environments)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
