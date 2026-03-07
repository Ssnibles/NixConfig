{ config, pkgs, ... }: {
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
  programs.java.enable = true;
}
