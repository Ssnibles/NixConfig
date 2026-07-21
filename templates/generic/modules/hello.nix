{ ... }: {
  perSystem = { pkgs, ... }: {
    packages.hello = pkgs.writeShellApplication {
      name = "hello";
      text = "echo 'Hello from your dendritic flake!'";
    };
  };
}
