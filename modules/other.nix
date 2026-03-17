{ config, ... }:
{
  # spotify-player: TUI Spotify client.
  # Store credentials in ~/.secrets/spotify/ (never in the Nix store).
  #
  #   mkdir -p ~/.secrets/spotify && chmod 700 ~/.secrets/spotify
  #   echo "CLIENT_ID"     > ~/.secrets/spotify/id.txt
  #   echo "CLIENT_SECRET" > ~/.secrets/spotify/secret.txt
  #   chmod 600 ~/.secrets/spotify/*.txt
  #
  # Get credentials at: https://developer.spotify.com/dashboard
  programs.spotify-player = {
    enable = true;
    settings = {
      client_id_command = "cat ${config.home.homeDirectory}/.secrets/spotify/id.txt";
      client_secret_command = "cat ${config.home.homeDirectory}/.secrets/spotify/secret.txt";
      device = {
        name = "Terminal";
        device_type = "computer";
      };
    };
  };

  programs.java.enable = true;
}
