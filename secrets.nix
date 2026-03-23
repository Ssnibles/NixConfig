# =============================================================================
# Secrets Configuration (Agenix)
# =============================================================================
# Defines which Age public keys can decrypt which secrets.
#
# SETUP INSTRUCTIONS:
# 1. Generate key: age-keygen -o ~/.config/agenix/key.txt
# 2. Copy the public key printed to stdout (starts with "age1...")
# 3. Replace the placeholder below with your actual key
# 4. Create secret files: secrets/<n>.age
# 5. Encrypt: age -r <public-key> -o secrets/<n>.age secrets/<n>.txt
#
# WARNING: The placeholder key below must be replaced before agenix can
# encrypt or decrypt any secrets. Attempting to use agenix with the
# placeholder will cause a build failure.
# =============================================================================
let
  # Add public keys for each user/host that needs secret access
  users = [
    # REPLACE THIS with your actual age public key, e.g.:
    # "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
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
