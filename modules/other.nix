{ config, ... }: {

  # ===========================================================================
  # SPOTIFY (TUI client)
  # spotify-player is a fast terminal client for Spotify.
  # Credentials are read from files rather than hardcoded so they stay out of
  # the Nix store (which is world-readable).
  #
  # Setup:
  #   mkdir -p ~/.secrets/spotify
  #   chmod 700 ~/.secrets/spotify
  #   echo "YOUR_CLIENT_ID"     > ~/.secrets/spotify/id.txt
  #   echo "YOUR_CLIENT_SECRET" > ~/.secrets/spotify/secret.txt
  #   chmod 600 ~/.secrets/spotify/*.txt
  #
  # Get credentials at: https://developer.spotify.com/dashboard
  #
  # ---------------------------------------------------------------------------
  # UPGRADING TO PROPER SECRET MANAGEMENT
  # ---------------------------------------------------------------------------
  # The `cat` approach works but has a couple of rough edges: the files aren't
  # managed by Nix, so there's no audit trail, and a process running as your
  # user can read them freely.
  #
  # When you're ready to harden this, two good options are:
  #
  #   agenix  — https://github.com/ryantm/agenix
  #     Encrypts secrets with your SSH key at rest; decrypts into
  #     /run/agenix/ (a tmpfs) on activation. Secrets never appear in the
  #     Nix store. Requires adding the agenix flake input and re-keying.
  #
  #   sops-nix — https://github.com/Mic92/sops-nix
  #     Uses SOPS + age/GPG. More flexible key management; good if you have
  #     multiple machines or team members needing shared secrets.
  #
  # Both integrate cleanly with home-manager and NixOS modules.
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
  # Enables a JDK and sets JAVA_HOME. The specific JDK version is set in
  # home.nix (jdk21).
  # ===========================================================================
  programs.java.enable = true;

}

