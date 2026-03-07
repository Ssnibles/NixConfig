{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    
    # Use fishAbbrs instead of aliases for better shell integration
    # (they expand in real-time)
    shellAbbrs = {
      v = "nvim";
      # Update the path below to the absolute path of your flake directory
      rebuild = "git -C ~/NixConfig/ add . && sudo nixos-rebuild switch --flake ~/NixConfig/#nixos";
    };

    interactiveShellInit = ''
      set -g fish_greeting ""
    '';

    plugins = with pkgs.fishPlugins; [
      { name = "grc"; src = grc.src; }
      { name = "z"; src = z.src; }
      { name = "pure"; src = pure.src; }
    ];
  };
}
