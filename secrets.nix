let
  # Your age public key — generate with: age-keygen -o ~/.config/agenix/key.txt
  # Then copy the public key line (starts with "age1...") here
  users = [
    "age1YOUR_PUBLIC_KEY_HERE" # Replace with your actual age public key
  ];

  systems = [ "nixos" ];
in
{
  "spotify-id.age".users = users;
  "spotify-id.age".systems = systems;

  "spotify-secret.age".users = users;
  "spotify-secret.age".systems = systems;
}
