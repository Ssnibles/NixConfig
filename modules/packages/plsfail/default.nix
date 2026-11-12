{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.plsfail = self.lib.mkSingleScript pkgs {
        name = "plsfail";
        file = "plsfail.py";
        src = ./.;
        description = "Run a command until it fails";
        program = "python3";
        interpreter = pkgs.python3;
      };
    };
}
