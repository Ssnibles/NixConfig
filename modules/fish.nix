{ pkgs, self, ... }: {
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
      # Fixed: Use self.outPath instead of hardcoded /home/josh/NixConfig
      rebuild = "git -C ${self.outPath} add . && sudo nixos-rebuild switch --flake ${self.outPath}#nixos";
    };
  };
}
