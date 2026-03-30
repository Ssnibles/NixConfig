# =============================================================================
# Neovim Module
# =============================================================================
# Installs Neovim with plugins and LSP tools.
# =============================================================================
{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraPackages = with pkgs; [
      # LSP servers
      nixd
      kotlin-language-server
      jdt-language-server
      lua-language-server
      marksman
      # Formatters
      nixfmt-rfc-style
      stylua
      black
      isort
      prettier
    ];

    plugins = with pkgs.vimPlugins; [
      # Treesitter with ALL language parsers you edit
      (nvim-treesitter.withPlugins (
        p: with p; [
          lua
          markdown
          latex
          nix
          vim
          bash
          kotlin
          java
          json
          yaml
          gitignore
          # ADDED: Missing parsers for languages you format
          javascript
          typescript
          tsx
          python
          html
          css
        ]
      ))
      # Core
      plenary-nvim
      nvim-lspconfig
      blink-cmp
      luasnip
      friendly-snippets
      copilot-lua
      fzf-lua
      oil-nvim
      statuscol-nvim
      fidget-nvim
      gitsigns-nvim
      noice-nvim
      markview-nvim
      nvim-web-devicons
      lualine-nvim
      indent-blankline-nvim
      nvim-treesitter-context
      neoscroll-nvim
      vague-nvim
      nvim-autopairs
      conform-nvim
      mini-nvim
      neogit
      vim-tmux-navigator
      leap-nvim
      grug-far-nvim
    ];
  };

  xdg.configFile."nvim" = {
    source = ../nvim;
    recursive = true;
  };
}
