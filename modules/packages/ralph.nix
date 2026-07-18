{ self, inputs, ... }:
{
  perSystem =
    {
      pkgs,
      lib,
      self',
      ...
    }:
    {
      packages.ralph = pkgs.rustPlatform.buildRustPackage rec {
        pname = "ralph-cli";
        version = "2.8.1";

        src = pkgs.fetchFromGitHub {
          owner = "mikeyobrien";
          repo = "ralph-orchestrator";
          rev = "v${version}";
          sha256 = "sha256-CH33GHXEV7eC0g3CAPNKV8O3HP3brNe5jnY5aC7veY0=";
        };

        cargoHash = "sha256-lNcSjVoCXCzccX5WbfaoOQiJ8SgttfepHP/0E61sRb0=";
        doCheck = false;
      };
    };
}
