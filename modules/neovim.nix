{ pkgs, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Define your required packages
    extraPackages = with pkgs; [
      nixd
      kotlin-language-server
      jdt-language-server
      nixpkgs-fmt
      lua-language-server
      stylua
      black
      prettier
    ];

    # Define your plugins
    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
      (nvim-treesitter.withPlugins (p: with p; [
        lua
        nix
        vim
        bash
        markdown
        kotlin
        java
        json
        yaml
        gitignore
      ]))

      plenary-nvim
      nvim-lspconfig
      blink-cmp
      luasnip
      friendly-snippets
      telescope-nvim
      fzf-lua
      oil-nvim
      statuscol-nvim
      smart-splits-nvim
      nvim-autopairs
      fidget-nvim
      gitsigns-nvim
      which-key-nvim
      noice-nvim
      conform-nvim
      catppuccin-nvim
      markview-nvim
    ];
  };

  # Link the local nvim directory to ~/.config/nvim 
  # This avoids path resolution issues with initLua and builtins.readFile 
  xdg.configFile."nvim" = {
    source = ../nvim;
    recursive = true;
  };
}
