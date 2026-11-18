{
  pkgs,
  ...
}:
{
  packages = with pkgs; [
    git
    ruff
  ];

  languages.python = {
    enable = true;
    uv.enable = true;
    uv.sync.enable = true;
  };

  scripts = {
    run.exec = "uv run python main.py";
    test.exec = "uv run pytest";
  };

  enterShell = ''
    echo "Python project: use 'run' or 'uv run python main.py'"
  '';
}
