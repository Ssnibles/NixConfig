{
  pkgs,
  ...
}:
{
  packages = with pkgs; [
    cmake
    git
    ninja
  ];

  languages.c.enable = true;

  scripts = {
    configure.exec = "cmake -S . -B build -G Ninja";
    build.exec = "cmake --build build";
    run.exec = "./build/@PACKAGE@";
  };

  enterShell = ''
    echo "C project: use 'configure', 'build', then 'run'"
  '';
}
