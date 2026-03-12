{ config, pkgs, ... }: {

  # ===========================================================================
  # SPOTIFY (TUI client)
  # spotify-player is a fast terminal client for Spotify.
  # Credentials are read from files rather than hardcoded so they stay out of
  # the Nix store (which is world-readable).
  #
  # Setup:
  #   mkdir -p ~/.secrets/spotify
  #   echo "YOUR_CLIENT_ID"     > ~/.secrets/spotify/id.txt
  #   echo "YOUR_CLIENT_SECRET" > ~/.secrets/spotify/secret.txt
  #
  # Get credentials at: https://developer.spotify.com/dashboard
  # ===========================================================================
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

  # ===========================================================================
  # JAVA
  # Enables a JDK and sets JAVA_HOME. The specific JDK version is picked by
  # nixpkgs defaults (currently jdk21 as set in home.nix extraPackages).
  # ===========================================================================
  programs.java.enable = true;

}

