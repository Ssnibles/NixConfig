{ config, pkgs, ... }:

{
  home.username = "josh";
  home.homeDirectory = "/home/josh";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    nixd
    nixpkgs-fmt
    lua-language-server
    code2prompt
    wl-clipboard
    firefox
    ghostty
    yazi
    mission-center
    # vicinae
    ripgrep
    nerd-fonts.fira-code
    grc
  ];

  # Only for my user
  # home-manager.users.josh = { };

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

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ssnibles";
        email = "joshua.breite@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };

  programs.vicinae = {
    enable = true;
    settings = {
      launcher_window = {
        layer_shell = {
          enabled = true;
          namespace = "vicinae";
        };
      };
      behaviour = {
        exit_on_launch = true;
      };
    };
  };

  home.sessionVariables = {
    SHELL = "${pkgs.fish}/bin/fish";
  };

  xdg.configFile."ghostty/config".text = ''
    command = ${pkgs.fish}/bin/fish
  '';

  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";
      bind = [
        "$mod, RETURN, exec, ghostty"
        "$mod, Q, killactive,"
        "$mod, E, exec, nautilus"
        "$mod, V, togglefloating,"
        "$mod, SPACE, exec, vicinae toggle"
      ];
      monitor = ", 1920x1080, auto, 1";
    };
  };

  systemd.user.services.vicinae = {
    Unit = {
      Description = "Vicinae launcher daemon";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.vicinae}/bin/vicinae server";
      Restart = "on-failure";
    };
    Install = { WantedBy = [ "graphical-session.target" ]; };
  };

  programs.neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      (nvim-treesitter.withPlugins (p: with p; [ lua nix vim bash markdown ]))
      plenary-nvim
      nvim-lspconfig
      blink-cmp
      nvim-autopairs
      telescope-nvim
      oil-nvim
      statuscol-nvim
      smart-splits-nvim
    ];
    extraLuaConfig = ''dofile("/home/josh/NixConfig/nvim/init.lua")'';
  };

  programs.home-manager.enable = true;
}
