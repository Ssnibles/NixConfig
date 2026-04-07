# =============================================================================
# Neovim Module (Home Manager)
# =============================================================================
# Installs Neovim with plugins and LSP / formatter tools.
# Optimized with minimal plugins and high-performance server tooling.
# =============================================================================
{ pkgs, ... }:
let
  tiny-code-action = pkgs.vimUtils.buildVimPlugin {
    pname = "tiny-code-action";
    version = "main";
    src = pkgs.fetchFromGitHub {
      owner = "rachartier";
      repo = "tiny-code-action.nvim";
      rev = "main";
      sha256 = "sha256-oZalIk5m+XtwvPWjI+Ds/IoM4nM0w9BEoI5YYI1B/PI=";
    };
    doCheck = false;
  };
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    extraPackages = with pkgs; [
      # LSP servers
      nixd
      lua-language-server
      pyright
      vtsls
      kotlin-language-server
      jdt-language-server
      marksman
      roslyn-ls

      # Formatters & language runtimes
      nixfmt
      stylua
      black
      isort
      prettier
      csharpier
      dotnet-sdk_10
      tree-sitter
      ripgrep
      fd
    ];
    plugins = with pkgs.vimPlugins; [
      tiny-code-action
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
          javascript
          typescript
          tsx
          python
          html
          css
          c_sharp
        ]
      ))
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
      roslyn-nvim
      tiny-inline-diagnostic-nvim
    ];
  };

  # Source Lua configuration from the repo root
  xdg.configFile."nvim" = {
    source = ../../nvim;
    recursive = true;
  };
}
