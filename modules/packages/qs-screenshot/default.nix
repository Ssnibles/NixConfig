{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.qs-screenshot = self.lib.mkSingleScript pkgs {
        name = "qs-screenshot";
        file = "qs-screenshot.sh";
        src = ./.;
        description = "Crop, save, copy or OCR a frozen screenshot from the Quickshell overlay";
        program = "bash";
      };
    };
}
