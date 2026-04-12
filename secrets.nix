# =============================================================================
# Secrets Configuration (Agenix)
# =============================================================================
# Defines which Age public keys can decrypt which secrets.
#
# SETUP INSTRUCTIONS:
#   1. Generate key: age-keygen -o ~/.config/agenix/key.txt
#   2. Export your public key:
#        Bash/Zsh: export AGENIX_USER_KEY="age1..."
#        Fish:     set -Ux AGENIX_USER_KEY (age-keygen -y ~/.config/agenix/key.txt)
#   3. Encrypt secrets:
#        agenix -e secrets/spotify-id.age
#        agenix -e secrets/spotify-secret.age
#
# Secret files:
#   - spotify-id.age     : Spotify API client ID
#   - spotify-secret.age : Spotify API client secret
# =============================================================================
let
  userKey = builtins.getEnv "AGENIX_USER_KEY";
  users = if userKey != "" then [ userKey ] else [ ];

  maybeSpotifyId = if users != [ ] then { "secrets/spotify-id.age".publicKeys = users; } else { };
  maybeSpotifySecret =
    if users != [ ] then { "secrets/spotify-secret.age".publicKeys = users; } else { };

in
maybeSpotifyId // maybeSpotifySecret
