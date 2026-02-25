{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting "" 
    '';
    plugins = [
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      { name = "z"; src = pkgs.fishPlugins.z.src; }
      { name = "pure"; src = pkgs.fishPlugins.pure.src; }
    ];
    shellAliases = {
      v = "nvim";
      rebuild = "git -C /home/josh/NixConfig add . && sudo nixos-rebuild switch --flake /home/josh/NixConfig#nixos";
    };
  };
}
