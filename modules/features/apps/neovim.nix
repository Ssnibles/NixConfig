# =============================================================================
# Neovim Editor Feature (NVF Flake Module)
# =============================================================================
# NVF framework configuration, language server dependencies, formatters,
# linters, Tree-Sitter grammars, Vim plugins, and nvim-src symlinking.
# =============================================================================
{ inputs, ... }:
{
  nixos.modules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    {
      imports = [
        inputs.nvf.nixosModules.default
      ];

      programs.nvf = {
        enable = true;
        defaultEditor = true;

        settings.vim = {
          viAlias = true;
          vimAlias = true;
          lineNumberMode = "relNumber";
          searchCase = "smart";
          undoFile.enable = true;

          clipboard = {
            enable = true;
            registers = "unnamedplus";
          };

          globals = {
            mapleader = " ";
            maplocalleader = "\\";

            neovide_font_family = "JetBrainsMono Nerd Font";
            neovide_font_size = 12;
            neovide_padding_top = 20;
            neovide_padding_bottom = 20;
            neovide_padding_left = 20;
            neovide_padding_right = 20;
            neovide_refresh_rate = 60;
            neovide_idle = true;
            neovide_vsync = true;
            neovide_cursor_vfx_mode = "";
            neovide_cursor_animation_length = 0.0;
            neovide_scroll_animation_length = 0.08;
            neovide_floating_blur = false;
            neovide_confirm_quit = true;
            neovide_remember_window_size = true;
          };

          options = {
            signcolumn = "yes";
            shiftwidth = 2;
            tabstop = 2;
            expandtab = true;
            smartindent = true;
            autoindent = true;
            shiftround = true;
            termguicolors = true;
            cursorline = true;
            showmode = false;
            wrap = false;
            linebreak = true;
            breakindent = true;
            conceallevel = 2;
            incsearch = true;
            inccommand = "split";
            splitright = true;
            splitbelow = true;
            splitkeep = "cursor";
            foldmethod = "expr";
            foldexpr = "v:lua.vim.treesitter.foldexpr()";
            foldlevelstart = 99;
            foldcolumn = "0";
            ttimeoutlen = 10;
            swapfile = false;
            autoread = true;
            mouse = "a";
            mousemodel = "extend";
            confirm = true;
            virtualedit = "block";
            pumheight = 12;
            wildmode = "longest:full,full";
            wildoptions = "fuzzy";
            wildignorecase = true;
            laststatus = 3;
            cmdheight = 0;
            showcmdloc = "statusline";
            grepformat = "%f:%l:%c:%m";
            shortmess = "sIcWFoO";
          };

          # ── Language Servers, Linters & Formatters ─────────────────────────
          extraPackages = with pkgs; [
            nixd
            lua-language-server
            pyright
            emmet-ls
            vscode-langservers-extracted
            kotlin-language-server
            jdt-language-server
            jdk
            marksman
            ltex-ls-plus
            imagemagick

            # qmlls from qt6.qtdeclarative, wrapped for QtQuick & Quickshell types
            (writeShellScriptBin "qmlls" ''
              exec "${pkgs.unstable.qt6.qtdeclarative}/bin/qmlls" \
                -I "${pkgs.unstable.qt6.qtdeclarative}/lib/qt-6/qml" \
                -I "${pkgs.unstable.quickshell}/lib/qt-6/qml" \
                "$@"
            '')

            nixfmt
            stylua
            black
            isort
            prettierd
            prettier
            shfmt
            ktlint
            google-java-format
            statix
            deadnix

            rust-analyzer
            rustfmt
            cargo
            rustc
            clippy
            zig
            (writeShellScriptBin "zls" ''
              export CPATH="${
                lib.makeSearchPathOutput "dev" "include" [
                  wayland
                  wlroots
                  libxkbcommon
                  libinput
                  libdrm
                ]
              }:${pixman}/include/pixman-1''${CPATH:+:$CPATH}"
              export PKG_CONFIG_PATH="${
                lib.makeSearchPathOutput "dev" "lib/pkgconfig" [
                  wayland
                  wlroots
                  pixman
                  libxkbcommon
                  libinput
                  libdrm
                  wayland-protocols
                ]
              }''${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
              exec "${zls}/bin/zls" "$@"
            '')
            pkg-config
            wayland
            wlroots
            wayland-protocols
            tinymist
            typst
            typstyle
            neovim-remote

            # C / C++ Tooling & Language Servers
            clang-tools
            cppcheck
            cpplint
            gdb
            cmake
            ninja
            gnumake

            python3Packages.debugpy
            delve
            lldb
            vscode-js-debug

            tree-sitter
          ];

          # ── Vim Plugins & Grammars ─────────────────────────────────────────
          startPlugins = with pkgs.vimPlugins; [
            (nvim-treesitter.withPlugins (p: [
              p.nix
              p.lua
              p.python
              p.bash
              p.typescript
              p.javascript
              p.kotlin
              p.java
              p.markdown
              p.markdown_inline
              p.latex
              p.bibtex
              p.html
              p.css
              p.typst
              p.c
              p.cpp
              p.zig
              p.go
              p.json
              p.yaml
              p.toml
              p.regex
              p.vim
              p.vimdoc
              p.query
              p.qmljs
            ]))
            nvim-treesitter-context
            nvim-treesitter-textobjects

            blink-cmp
            blink-cmp-spell
            blink-cmp-copilot
            luasnip
            friendly-snippets
            copilot-lua
            nvim-lint

            nvim-dap
            nvim-dap-ui
            nvim-dap-virtual-text
            nvim-dap-python
            nvim-nio

            fzf-lua
            oil-nvim
            flash-nvim
            smart-splits-nvim

            gitsigns-nvim
            neogit

            grug-far-nvim
            inc-rename-nvim

            mini-nvim
            plenary-nvim
            typst-preview-nvim
            rustaceanvim
            clangd_extensions-nvim
            aerial-nvim

            tiny-inline-diagnostic-nvim
            conform-nvim
            fidget-nvim
          ];

          luaConfigRC.user-config = ''
            dofile(vim.fn.stdpath("config") .. "/init.lua")
          '';
        };
      };

      # ── System Activation Script ───────────────────────────────────────────
      # Links the custom Lua Neovim configuration tree in modules/features/nvim-src
      system.activationScripts.nvf-config = ''
        mkdir -p /home/${config.username}/.config
        chown -R ${config.username}:users /home/${config.username}/.config
        ln -sfn /home/${config.username}/NixConfig/modules/features/nvim-src /home/${config.username}/.config/nvim
        ln -sfn /home/${config.username}/NixConfig/modules/features/nvim-src /home/${config.username}/.config/nvf
        chown -h ${config.username}:users /home/${config.username}/.config/nvim /home/${config.username}/.config/nvf
      '';
    };
}
