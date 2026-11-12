{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.dualsense-pair = self.lib.mkSingleScript pkgs {
        name = "dualsense-pair";
        file = "dualsense-pair.sh";
        src = ./.;
        description = "Pair or re-pair a PlayStation 5 DualSense controller over Bluetooth";
        program = "bash";
      };
    };
}
