{ pkgs, self, ... }: {
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Corrected: Use jdt-language-server for jdtls
    extraPackages = with pkgs; [
      nixd
      kotlin-language-server
      jdt-language-server
      nixpkgs-fmt
      lua-language-server
    ];

    plugins = with pkgs.vimPlugins; [
      # Added nvim-treesitter core plugin to fix module load error
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
      oil-nvim
      statuscol-nvim
      smart-splits-nvim
      nvim-autopairs
      fidget-nvim
      gitsigns-nvim
      which-key-nvim
      noice-nvim
      catppuccin-nvim
      markview-nvim
    ];

    initLua = builtins.readFile ../nvim/init.lua;
  };
}
