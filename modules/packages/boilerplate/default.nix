{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.boilerplate = self.lib.mkSingleScript pkgs {
        name = "boilerplate";
        file = "boilerplate.py";
        src = ./.;
        description = "Generate boilerplate Nix modules";
        program = "python3";
        interpreter = pkgs.python3;
      };
    };
}
