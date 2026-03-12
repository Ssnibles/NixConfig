{ pkgs, ... }: {

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # ===========================================================================
    # EXTERNAL TOOLS
    # Language servers, formatters, and linters placed on $PATH for neovim.
    # ===========================================================================
    extraPackages = with pkgs; [
      # Language servers
      nixd
      kotlin-language-server
      jdt-language-server
      lua-language-server

      # Formatters (used by conform.nvim)
      nixpkgs-fmt # nix
      stylua # lua
      black # python
      prettier # js/ts/json/yaml/etc.
      isort # python import sorting (runs before black)
    ];

    # ===========================================================================
    # PLUGINS
    # ===========================================================================
    plugins = with pkgs.vimPlugins; [
      # Syntax highlighting & indentation
      nvim-treesitter
      (nvim-treesitter.withPlugins (p: with p; [
        lua
        markdown
        nix
        vim
        bash
        kotlin
        java
        json
        yaml
        gitignore
      ]))

      # LSP & completion
      nvim-lspconfig # Helpers / :LspInfo (used minimally alongside built-in LSP)
      blink-cmp # Fast async completion engine
      luasnip # Snippet engine required by blink-cmp
      friendly-snippets # VS Code-format snippet collection

      # Fuzzy finding — fzf-lua is the primary picker; telescope removed.
      fzf-lua

      # File management
      oil-nvim

      # UI enhancements
      statuscol-nvim
      smart-splits-nvim
      nvim-autopairs
      fidget-nvim
      gitsigns-nvim
      which-key-nvim
      noice-nvim
      markview-nvim

      # Formatting
      conform-nvim

      # Colorscheme
      vague-nvim
    ];
  };

  # ===========================================================================
  # CONFIG FILES
  # Symlink the local `nvim/` directory to ~/.config/nvim.
  # ===========================================================================
  xdg.configFile."nvim" = {
    source = ../nvim;
    recursive = true;
  };
}

