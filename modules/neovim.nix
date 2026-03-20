# =============================================================================
# Neovim Module
# =============================================================================
# Installs Neovim, plugins, and LSP tools.
# Symlinks the ./nvim directory to ~/.config/nvim.
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
      # Formatters
      nixfmt-rfc-style
      stylua
      black
      isort
      prettier
    ];
    plugins = with pkgs.vimPlugins; [
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
      plenary-nvim
      nvim-lspconfig
      blink-cmp
      luasnip
      friendly-snippets
      copilot-lua
      # copilot-vim
      avante-nvim
      fzf-lua
      oil-nvim
      statuscol-nvim
      smart-splits-nvim
      nvim-autopairs
      fidget-nvim
      gitsigns-nvim
      noice-nvim
      markview-nvim
      nvim-web-devicons
      lualine-nvim
      indent-blankline-nvim
      nvim-treesitter-context
      neoscroll-nvim
      conform-nvim
      vague-nvim
      mini-nvim
    ];
  };

  # Symlink custom config
  xdg.configFile."nvim" = {
    source = ../nvim;
    recursive = true;
  };
}
