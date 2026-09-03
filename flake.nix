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

    # Packages
    millennium = {
      url = "github:SteamClientHomebrew/Millennium?dir=packages/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mangowc = {
      # url = "github:mangowm/mango";
      url = "path:/home/josh/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tuxedo = {
      url = "github:webstonehq/tuxedo";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pomodoro.url = "github:Ssnibles/pomodoro";
    pomodoro.inputs.nixpkgs.follows = "nixpkgs";
    # For local development without pushing every change, swap in:
    # pomodoro.url = "path:/home/josh/pomodoro";
    # pomodoro.inputs.nixpkgs.follows = "nixpkgs";

    dwl.url = "path:/home/josh/dwl";
    dwl.inputs.nixpkgs.follows = "nixpkgs";
    # When pushed to GitHub, switch to:
    # dwl.url = "github:Ssnibles/dwl";
    # dwl.inputs.nixpkgs.follows = "nixpkgs";

    niri-float-sticky.url = "github:probeldev/niri-float-sticky";
    niri-float-sticky.inputs.nixpkgs.follows = "nixpkgs";

    devenv = {
      url = "github:cachix/devenv";
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
