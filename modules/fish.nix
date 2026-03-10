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
  xdg.configFile."ghostty/config".text = ''
    command = ${pkgs.fish}/bin/fish
    font-size = 12
    cursor-style = bar
    background = 282c34
    foreground = ffffff
    window-decoration = false
    window-save-state = default
    window-theme = dark
    command-color = true
    terminal-version = "xterm-256color"
    renderer = opengl
    clipboard-read = allow
    clipboard-write = allow
  '';
}
