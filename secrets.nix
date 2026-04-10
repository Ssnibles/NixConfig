# =============================================================================
# Secrets Configuration (Agenix)
# =============================================================================
# Defines which Age public keys can decrypt which secrets.
#
# SETUP INSTRUCTIONS:
#   1. Generate key: age-keygen -o ~/.config/agenix/key.txt
#   2. Export your public key for the current shell:
#        export AGENIX_USER_KEY="age1..."
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

  maybeSpotifyId =
    if users != [ ] && builtins.pathExists ./secrets/spotify-id.age then
      { "spotify-id.age".publicKeys = users; }
    else
      { };
  maybeSpotifySecret =
    if users != [ ] && builtins.pathExists ./secrets/spotify-secret.age then
      { "spotify-secret.age".publicKeys = users; }
    else
      { };

in
maybeSpotifyId // maybeSpotifySecret
