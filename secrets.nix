let
  # Generate your age key with: age-keygen -o ~/.config/agenix/key.txt
  # Paste the public key (starts with "age1...") below.
  users = [ "age1REPLACE_WITH_YOUR_AGE_PUBLIC_KEY" ];
in
{
  "spotify-id.age".publicKeys = users;
  "spotify-secret.age".publicKeys = users;
}
