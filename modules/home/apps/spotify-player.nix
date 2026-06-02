{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:
let
  spotifyIdFile = ../../secrets/spotify-id.age;
  spotifySecretFile = ../../secrets/spotify-secret.age;
  spotifySecretsAvailable =
    builtins.pathExists spotifyIdFile && builtins.pathExists spotifySecretFile;
in
{
  programs.spotify-player = {
    enable = spotifySecretsAvailable;
    settings = {
      client_id_command = "cat /run/agenix/spotify-id";
      client_secret_command = "cat /run/agenix/spotify-secret";
      device = {
        name = "Terminal";
        device_type = "computer";
      };
    };
  };

  warnings = lib.optional (!spotifySecretsAvailable) ''
    Spotify credentials are not configured.
    Add secrets/spotify-id.age and secrets/spotify-secret.age to enable spotify-player.
  '';
}
