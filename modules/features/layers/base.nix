{ self, inputs, ... }:
{
  flake.nixosModules.base =
    { pkgs, lib, ... }:
    {
      imports = [
        inputs.hjem.nixosModules.default
        ../../options.nix
      ];

      config = {
        username = "jingus";
        nixpkgs.overlays = [ inputs.millennium.overlays.default ];
        # Set your time zone.
        time.timeZone = "America/Chicago";

        # Select internationalisation properties.
        i18n.defaultLocale = "en_US.UTF-8";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "en_US.UTF-8";
          LC_IDENTIFICATION = "en_US.UTF-8";
          LC_MEASUREMENT = "en_US.UTF-8";
          LC_MONETARY = "en_US.UTF-8";
          LC_NAME = "en_US.UTF-8";
          LC_NUMERIC = "en_US.UTF-8";
          LC_PAPER = "en_US.UTF-8";
          LC_TELEPHONE = "en_US.UTF-8";
          LC_TIME = "en_US.UTF-8";
        };

        # Enable the X11 windowing system.
        services.xserver.enable = true;

        # Configure keymap in X11
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        # Enable CUPS to print documents.
        services.printing.enable = true;

        # Enable touchpad support (enabled default in most desktopManager).
        # services.xserver.libinput.enable = true;

        # Some programs need SUID wrappers, can be configured further or are
        # started in user sessions.
        # programs.mtr.enable = true;
        # programs.gnupg.agent = {
        #   enable = true;
        #   enableSSHSupport = true;
        # };

        # List services that you want to enable:

        # Optimizations and garbage collection
        nix.optimise.automatic = true;
        nix.optimise.dates = [ "03:45" ];
        nix.gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than 30d";
        };
      };

    };
}
