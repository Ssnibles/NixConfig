{
  pkgs,
  ...
}:
{
  packages = with pkgs; [
    git
  ];

  languages.rust.enable = true;

  scripts = {
    run.exec = "cargo run";
    test.exec = "cargo test";
  };

  enterShell = ''
    echo "Rust project: use 'run' or 'cargo run'"
  '';
}
