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
    };

    mangowc = {
      url = "github:mangowm/mango/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    scenefx = {
      url = "github:wlrfx/scenefx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Local development checkouts. Use the git fetcher (not `path:`) so the
    # lock is content-addressed by revision: `path:` inputs hash the whole
    # tree including .git/.jj, so any jj/git operation changed the NAR hash and
    # broke evaluation. Commit changes in these repos to have them picked up
    # (the runtime mango-dev wrapper still prefers ~/mango/result for uncommitted
    # mango iteration).
    mangowc-local = {
      url = "git+file:///home/josh/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ytplay = {
      url = "git+file:///home/josh/ytplay";
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

    # pomodoro.url = "github:Ssnibles/pomodoro";
    # pomodoro.inputs.nixpkgs.follows = "nixpkgs";
    # For local development without pushing every change, swap in:
    # pomodoro.url = "path:/home/josh/pomodoro";
    # pomodoro.inputs.nixpkgs.follows = "nixpkgs";

    devenv = {
      url = "github:cachix/devenv";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Flatpak manager. Adds services.flatpak.remotes/.packages on
    # top of NixOS' built-in module (which only provides `enable`).
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=v0.7.0";
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
