# =============================================================================
# Secrets Configuration (Agenix)
# =============================================================================
# Defines which Age public keys can decrypt which secrets.
#
# SETUP INSTRUCTIONS:
# 1. Generate key: age-keygen -o ~/.config/agenix/key.txt
# 2. Copy the public key (starts with "age1...")
# 3. Replace the placeholder in the 'users' list below
# 4. Create secret files: secrets/<name>.age
# 5. Encrypt: age -r <public-key> -o secrets/<name>.age secrets/<name>.txt
# =============================================================================
let
  # Add public keys for each user/host that needs secret access
  users = [
    # REPLACE THIS with your actual age public key
    "age1REPLACE_WITH_YOUR_AGE_PUBLIC_KEY"
  ];
  desktopSecrets = {
    "spotify-id.age".publicKeys = users;
    "spotify-secret.age".publicKeys = users;
  };
  laptopSecrets = {
    # Add laptop-specific secrets here
  };
in
desktopSecrets // laptopSecrets
