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
    defaultEditor = true; # Sets $EDITOR to nvim
    viAlias = true; # Alias 'vi' to nvim
    vimAlias = true; # Alias 'vim' to nvim

    # External dependencies required by Neovim or its plugins
    extraPackages = with pkgs; [
      # LSP servers (Language Server Protocol)
      nixd # Nix
      kotlin-language-server # Kotlin
      jdt-language-server # Java
      lua-language-server # Lua
      marksman # Markdown

      # Formatters & Linters
      nixfmt-rfc-style # Official Nix formatting
      stylua # Lua formatting
      black # Python formatting
      isort # Python import sorting
      prettier # Web/Markdown formatting
    ];

    # Neovim plugins managed via Nix
    plugins = with pkgs.vimPlugins; [
      # Syntax highlighting and code parsing
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
        ]
      ))

      # Core libraries and LSP integration
      plenary-nvim # Common Lua functions used by many plugins
      nvim-lspconfig # Quickstart configs for Nvim LSP
      blink-cmp # Modern completion engine
      luasnip # Snippet engine
      friendly-snippets # Pre-configured snippet collection

      # AI Assistance
      copilot-lua # GitHub Copilot integration

      # Navigation and File Management
      fzf-lua # Fuzzy finding
      oil-nvim # File explorer edited like a normal buffer

      # UI Enhancements
      statuscol-nvim # Customizable status column (folds, signs)
      fidget-nvim # LSP progress notifications
      gitsigns-nvim # Git integration in the sign column
      noice-nvim # Overhaul for messages, cmdline, and popupmenu
      markview-nvim # Markdown preview/styling
      nvim-web-devicons # Icons for various plugins
      lualine-nvim # Sleek status line
      indent-blankline-nvim # Indentation guides
      nvim-treesitter-context # Sticky scroll for code context
      neoscroll-nvim # Smooth scrolling
      vague-nvim # Colorscheme

      # Utilities
      nvim-autopairs # Automatic bracket closing
      conform-nvim # Formatter plugin
      mini-nvim # Collection of small, modular Lua plugins
      neogit # Magit-inspired Git interface for Neovim
      vim-tmux-navigator # Seamless navigation between Vim and tmux splits
      leap-nvim # Fast navigation by jumping to any location in the visible buffer
      grug-far-nvim # Interactive find-and-replace (ripgrep + sed TUI)
    ];
  };

  # Symlink the local configuration directory to the XDG config path
  # This allows you to manage your init.lua and lua/ folder separately
  xdg.configFile."nvim" = {
    source = ../nvim;
    recursive = true;
  };
}
