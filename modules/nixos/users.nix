{ pkgs, lib, hostProfile, ... }:

let
  spotifyIdAge = ../../secrets/spotify-id.age;
  spotifySecretAge = ../../secrets/spotify-secret.age;
in
{
  users.users.${hostProfile.user} = {
    isNormalUser = true;
    description = hostProfile.user;
    shell = pkgs.fish;
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "input"
      "uinput"
      "plugdev"
    ]
    ++ lib.optionals hostProfile.isDesktop [ "i2c" ];
  };

  age.secrets = lib.mkMerge [
    (lib.mkIf (builtins.pathExists spotifyIdAge) {
      spotify-id = {
        file = spotifyIdAge;
        owner = hostProfile.user;
        mode = "0400";
      };
    })
    (lib.mkIf (builtins.pathExists spotifySecretAge) {
      spotify-secret = {
        file = spotifySecretAge;
        owner = hostProfile.user;
        mode = "0400";
      };
    })
  ];
}
