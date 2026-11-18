{
  pkgs,
  ...
}:
{
  packages = with pkgs; [
    git
  ];

  languages.go.enable = true;

  scripts = {
    run.exec = "go run .";
    test.exec = "go test ./...";
  };

  enterShell = ''
    echo "Go project: use 'run' or 'go run .'"
  '';
}
