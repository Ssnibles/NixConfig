{ pkgs, ... }: {

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # ===========================================================================
    # EXTERNAL TOOLS
    # Language servers and formatters placed on $PATH for neovim.
    # These are intentionally NOT duplicated in home.nix — if you want a tool
    # available in your shell as well as inside neovim, add it only here:
    # neovim's extraPackages are visible on the PATH that neovim itself sees,
    # and with `useUserPackages = true` they also land in your profile.
    # ===========================================================================
    extraPackages = with pkgs; [
      # Language servers
      nixd
      kotlin-language-server
      jdt-language-server
      lua-language-server

      # Formatters (used by conform.nvim)
      # nixfmt-rfc-style is the community-standard Nix formatter (replaces
      # the older nixpkgs-fmt). It is what nixpkgs itself uses upstream.
      nixfmt-rfc-style # nix
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

      # Fuzzy finding
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

      # Icons — required by lualine; used by oil, fzf-lua, etc.
      nvim-web-devicons

      # Statusline
      lualine-nvim

      # Indent guides
      indent-blankline-nvim

      # Smooth scrolling
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

