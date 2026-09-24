{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";

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

    mangowc-local = {
      url = "path:/home/josh/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ytplay = {
      url = "path:/home/josh/ytplay";
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
      inputs.nixpkgs.follow = "nixpkgs";
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
