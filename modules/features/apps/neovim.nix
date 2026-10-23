# Neovim with NVF.
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
          # Nightly Neovim. NVF adds the plugins below.
          package = inputs.neovim-nightly.packages.${pkgs.stdenv.hostPlatform.system}.neovim;

          viAlias = true;
          vimAlias = true;

          # Options, keymaps, globals, and themes live in the Lua tree at
          # modules/features/nvim-src. NVF only wraps the plugins here.
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

            # PHP
            intelephense
            php
            php84Packages.composer
            php84Packages.php-cs-fixer
            phpstan
            ltex-ls-plus
            imagemagick

            # qmlls wrapped with the QtQuick and Quickshell types.
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
            rustc
            clippy
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
            tinymist
            typstyle
            vtsls

            # C and C++ tools.
            clang-tools
            cppcheck
            gdb
            cmake
            ninja
            gnumake

            python3Packages.debugpy
            delve
            gopls
            lldb
            vscode-js-debug

            tree-sitter
          ];

          # Plugins and grammars.
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
              p.php
              p.phpdoc
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
            grug-far-nvim
            inc-rename-nvim

            markview-nvim
            dial-nvim
            goto-preview
            nvim-ts-autotag

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

      environment.systemPackages = [
        pkgs.neovim-remote
      ];

      # Link ~/.config/nvim and ~/.config/nvf to the Lua tree in
      # modules/features/nvim-src. This is handled by nixos.liveLinks, so
      # activation does not change ownership of all of ~/.config.
      nixos.liveLinks = {
        "nvim-config" = {
          source = "${config.nixos.configRepo}/modules/features/nvim-src";
          target = ".config/nvim";
        };
        "nvf-config" = {
          source = "${config.nixos.configRepo}/modules/features/nvim-src";
          target = ".config/nvf";
        };
      };
    };
}
