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

      # Icons — required by lualine and used by oil, fzf-lua, etc.
      # nvim-web-devicons reads your Nerd Font (JetBrains Mono is already
      # installed) and provides file-type icons across plugins.
      nvim-web-devicons

      # Statusline — lualine replaces the default statusline with a themed bar
      # built from the vague.nvim palette. globalstatus = true (set in init.lua)
      # gives a single bar at the bottom instead of one per split.
      lualine-nvim

      # Indent guides — draws subtle │ lines at each indent level and
      # highlights the active scope in vague keyword blue.
      indent-blankline-nvim

      # Smooth scrolling — animates <C-u>/<C-d> and friends so large jumps
      # are easier to follow visually.
      neoscroll-nvim

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

