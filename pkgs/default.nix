{ inputs }:

final: prev:
let
  inherit (prev) lib callPackage;

  # Auto-import every subdirectory that contains a default.nix as a custom package.
  # Each package is called with `inputs` available so it can access flake inputs.
  customPackages = lib.pipe (builtins.readDir ./.) [
    (lib.filterAttrs (
      name: type: type == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
    ))
    (lib.mapAttrs (name: _: callPackage (./. + "/${name}") { inherit inputs; }))
  ];
in

customPackages
// {
  # Make unstable nixpkgs available as pkgs.unstable
  unstable = import inputs.nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    config = {
      allowUnfree = true;
      allowInsecure = true;
      permittedInsecurePackages = [
        "electron-40.10.5"
      ];
    };
  };
}
