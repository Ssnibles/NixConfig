{ self, inputs, ... }:
{
  perSystem = { pkgs, lib, ... }: {
    packages.vivado-env = pkgs.buildFHSEnv {
      name = "vivado-env";
      targetPkgs = pkgs: (with pkgs; [
        ncurses5
        ncurses
        libxcrypt-legacy
        libpng
        libusb1
        systemd
        pixman
        zlib
        libuuid
        bash
        coreutils
        stdenv.cc.cc
        libxext
        libx11
        libxrender
        libxtst
        libxi
        libxft
        libxcb
        freetype
        fontconfig
        glib
        gtk2
        gtk3
        graphviz
        gcc
        unzip
        nettools
      ]);

      profile = ''
        export LD_LIBRARY_PATH=/usr/lib:/usr/lib64:$LD_LIBRARY_PATH
      '';

      runScript = ''
        env LIBRARY_PATH=/usr/lib \
        C_INCLUDE_PATH=/usr/include \
        CPLUS_INCLUDE_PATH=/usr/include \
        CMAKE_LIBRARY_PATH=/usr/lib \
        CMAKE_INCLUDE_PATH=/usr/include \
        bash
      '';
    };
  };

  flake.nixosModules.vivado =
    { pkgs, lib, config, ... }:
    {
      options.programs.vivado = {
        enable = lib.mkEnableOption "AMD Vivado udev rules for FPGA JTAG";
      };

      config = lib.mkIf config.programs.vivado.enable {
        services.udev.extraRules = ''
          # Digilent Adept USB (JTAG cables for Basys/Nexys/Arty boards)
          ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6010", MODE="666", GROUP="dialout"
          # Xilinx Platform Cable USB II
          ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="0008", MODE="666", GROUP="dialout"
          ATTRS{idVendor}=="03fd", ATTRS{idProduct}=="0013", MODE="666", GROUP="dialout"
          # Xilinx USB JTAG (newer boards)
          ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6014", MODE="666", GROUP="dialout"
        '';

        environment.systemPackages = [
          self.packages.${pkgs.stdenv.hostPlatform.system}.vivado-env
        ];
      };
    };
}
