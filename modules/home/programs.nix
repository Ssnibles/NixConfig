# =============================================================================
# Miscellaneous Program Configuration
# =============================================================================
# Configured Home Manager programs that don't warrant their own file.
# Currently: spotify-player (TUI client) and Java runtime.
# =============================================================================
{ config, ... }:
{
  # Spotify Player (TUI client)
  programs.spotify-player = {
    enable = true;
    settings = {
      # Secrets are stored outside the Nix store – see secrets.nix for setup.
      client_id_command = "cat ${config.home.homeDirectory}/.secrets/spotify/id.txt";
      client_secret_command = "cat ${config.home.homeDirectory}/.secrets/spotify/secret.txt";
      device = {
        name = "Terminal";
        device_type = "computer";
      };
    };
  };

  # Direnv (Nix integration for shell environments)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
