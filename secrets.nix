let
  # Your age public key — generate with: age-keygen -o ~/.config/agenix/key.txt
  # Then copy the public key line (starts with "age1...") here.
  #
  # IMPORTANT: Replace the placeholder below with your actual age public key
  # before running nixos-rebuild, or agenix will fail to decrypt secrets.
  # Example: "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
  users = [
    "age1REPLACE_WITH_YOUR_AGE_PUBLIC_KEY" # <-- run: age-keygen -o ~/.config/agenix/key.txt
  ];

  systems = [ "nixos" ];
in
{
  "spotify-id.age".users = users;
  "spotify-id.age".systems = systems;

  "spotify-secret.age".users = users;
  "spotify-secret.age".systems = systems;
}
