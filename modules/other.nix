{
  config,
  pkgs,
  lib,
  ...
}:
{
  # ===========================================================================
  # SPOTIFY (TUI client)
  # spotify-player is a fast terminal client for Spotify.
  #
  # Credentials are managed via agenix for secure secret handling.
  # Secrets are encrypted at rest and decrypted to /run/agenix/ on activation.
  #
  # Setup instructions:
  #   1. Install agenix CLI: nix profile install github:ryantm/agenix
  #   2. Generate your age key: age-keygen -o ~/.config/agenix/key.txt
  #   3. Add your public key to secrets.nix
  #   4. Create secrets:
  #      echo "YOUR_CLIENT_ID" | agenix -e secrets/spotify-id.age
  #      echo "YOUR_CLIENT_SECRET" | agenix -e secrets/spotify-secret.age
  #   5. Commit the .age files (NOT the decrypted contents)
  #
  # Get credentials at: https://developer.spotify.com/dashboard
  # ===========================================================================
  programs.spotify-player = {
    enable = true;
    settings = {
      # Read from agenix-decrypted secrets in /run/agenix/
      client_id_command = "cat /run/agenix/spotify-id";
      client_secret_command = "cat /run/agenix/spotify-secret";

      device = {
        name = "Terminal";
        device_type = "computer";
      };
    };
  };

  # ===========================================================================
  # JAVA
  # Enables a JDK and sets JAVA_HOME. The specific JDK version is set in
  # home.nix (jdk21).
  # ===========================================================================
  programs.java.enable = true;
}
