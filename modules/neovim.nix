{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Language servers and formatters on $PATH for Neovim.
    # With useUserPackages = true these also land in the user profile.
    extraPackages = with pkgs; [
      # LSP servers
      nixd
      kotlin-language-server
      jdt-language-server
      lua-language-server

      # Formatters (conform.nvim)
      nixfmt-rfc-style # nix  (nixpkgs upstream standard)
      stylua # lua
      black # python
      isort # python import sorting (runs before black)
      prettier # js / ts / json / yaml / markdown
    ];

    plugins = with pkgs.vimPlugins; [
      # Syntax / indentation
      (nvim-treesitter.withPlugins (
        p: with p; [
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
        ]
      ))

      # LSP / completion
      nvim-lspconfig
      blink-cmp
      luasnip
      friendly-snippets

      # Fuzzy finding
      fzf-lua

      # File management
      oil-nvim

      # UI
      statuscol-nvim
      smart-splits-nvim
      nvim-autopairs
      fidget-nvim
      gitsigns-nvim
      which-key-nvim
      noice-nvim
      markview-nvim
      nvim-web-devicons

      # Statusline / indent
      lualine-nvim
      indent-blankline-nvim

      # Scrolling / formatting
      neoscroll-nvim
      conform-nvim

      # Colourscheme
      vague-nvim

      mini-nvim
      nvim-treesitter-context
    ];
  };

  # Symlink the nvim/ directory from the repo to ~/.config/nvim.
  xdg.configFile."nvim" = {
    source = ../nvim;
    recursive = true;
  };
}
