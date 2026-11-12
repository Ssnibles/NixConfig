{
  inputs = {
    # `nixpkgs` is the default for the host systems and for every input that
    # follows it. Flip the follows between "nixpkgs-unstable" and
    # "nixpkgs-stable" to move the whole system between channels; both stay
    # available as pkgs.unstable.* / pkgs.stable.*.
    nixpkgs.follows = "nixpkgs-unstable";

    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Weekly-updated nix-index database: powers fish/bash/zsh
    # command-not-found suggestions and `nix-locate`.
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    hjem = {
      url = "github:feel-co/hjem";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf.url = "github:NotAShelf/nvf";
    nvf.inputs.nixpkgs.follows = "nixpkgs";

    # Nightly Neovim, wired into NVF through `programs.nvf.settings.vim`.
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
      # Upstream pins millennium-src to an older release that predates the
      # MILLENNIUM_LINUX_X64 option, so the 64-bit build tries to compile the
      # 32-bit sources with -m32 and fails. Track the flake's own commit.
      inputs.millennium-src.url = "github:SteamClientHomebrew/Millennium";
    };

    mangowc = {
      url = "github:mangowm/mango/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    scenefx = {
      url = "github:wlrfx/scenefx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Local development checkouts. The default is the public fork so a fresh
    # clone evaluates anywhere; build.sh adds --override-input when the local
    # checkout exists. The runtime mango-dev wrapper also prefers
    # ~/mango/result, so uncommitted mango iteration still works.
    mangowc-local = {
      url = "github:Ssnibles/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ytplay = {
      url = "github:Ssnibles/ytplay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tuxedo = {
      url = "github:webstonehq/tuxedo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-agent = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Required by devenv's generated container shell output, which
    # `nix flake check` evaluates.
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mk-shell-bin.url = "github:rrbutani/nix-mk-shell-bin";

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak manager. Adds services.flatpak.remotes/.packages on
    # top of NixOS' built-in module (which only provides `enable`).
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";

    # Minecraft Bedrock (Windows GDK build) on Linux, via Wine/Proton with
    # native Xbox sign-in. The flake exposes a single wrapped package.
    bedrock-on-linux = {
      url = "github:Wyze3306/BedrockOnLinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
        (inputs.import-tree ./modules)
      ];
    };
}
