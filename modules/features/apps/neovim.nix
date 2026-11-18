# Neovim from the nightly overlay. Nix owns the package, plugins and toolchain;
# the Lua tree in modules/features/nvim-src owns configuration and is symlinked
# into the home directory, so Lua edits need no rebuild.
{ inputs, ... }:
{
  flake.nixosModules.shared =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    let
      # Jars for eclipse.jdt.ls, taken from the VS Code extensions that ship the
      # java-debug adapter and the JUnit runner. nvim-jdtls loads them through
      # `init_options.bundles`; java.lua reads them from NVIM_JAVA_BUNDLES.
      extensionJars =
        extension: subdir: excluded:
        let
          dir = "${extension}/share/vscode/extensions/${subdir}/server";
        in
        map (name: "${dir}/${name}") (
          builtins.filter (name: lib.hasSuffix ".jar" name && !(builtins.elem name excluded)) (
            builtins.attrNames (builtins.readDir dir)
          )
        );

      javaBundles =
        extensionJars pkgs.vscode-extensions.vscjava.vscode-java-debug "vscjava.vscode-java-debug" [ ]
        ++ extensionJars pkgs.vscode-extensions.vscjava.vscode-java-test "vscjava.vscode-java-test" [
          "com.microsoft.java.test.runner-jar-with-dependencies.jar"
          "jacocoagent.jar"
        ];

      # Everything the Lua tree calls: language servers, formatters, linters,
      # debug adapters and helper binaries.
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

        # qmlls wrapped with the QtQuick and Quickshell types.
        (writeShellScriptBin "qmlls" ''
          exec "${pkgs.qt6.qtdeclarative}/bin/qmlls" \
            -I "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml" \
            -I "${pkgs.quickshell}/lib/qt-6/qml" \
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
      ];

      plugins = with pkgs.vimPlugins; [
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
          p.rust
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
        nvim-dap-view
        nvim-dap-python
        nvim-jdtls

        fzf-lua
        oil-nvim
        flash-nvim
        smart-splits-nvim

        gitsigns-nvim
        grug-far-nvim
        inc-rename-nvim

        indent-blankline-nvim

        markview-nvim
        dial-nvim
        goto-preview
        nvim-ts-autotag

        mini-nvim
        typst-preview-nvim
        rustaceanvim
        clangd_extensions-nvim
        aerial-nvim
        tiny-inline-diagnostic-nvim
        conform-nvim
        fidget-nvim
      ];

      # wrapRc = false keeps VIMINIT unset, so Neovim loads ~/.config/nvim like
      # any normal install. The plugins are injected through packpath instead.
      neovim =
        pkgs.wrapNeovimUnstable inputs.neovim-nightly.packages.${pkgs.stdenv.hostPlatform.system}.neovim
          {
            wrapRc = false;
            viAlias = true;
            vimAlias = true;
            inherit plugins;
            wrapperArgs = [
              "--prefix"
              "PATH"
              ":"
              (lib.makeBinPath extraPackages)
              "--set"
              "NVIM_JAVA_BUNDLES"
              (lib.concatStringsSep ":" javaBundles)
            ];
          };
    in
    {
      environment.variables.EDITOR = lib.mkDefault "nvim";

      environment.systemPackages = [
        neovim
        pkgs.neovim-remote
      ];

      # Link the Lua tree into ~/.config/nvim. Root gets the same link so
      # `sudo nvim` runs the same configuration.
      nixos.liveLinks = {
        "nvim-config" = {
          source = "${config.nixos.configRepo}/modules/features/nvim-src";
          target = ".config/nvim";
        };
        "nvim-config-root" = {
          source = "${config.nixos.configRepo}/modules/features/nvim-src";
          target = ".config/nvim";
          user = "root";
        };
      };
    };
}
