{
  pkgs,
  ...
}:
{
  packages = with pkgs; [
    git
  ];

  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
    pnpm.enable = true;
    pnpm.install.enable = true;
  };
  languages.typescript.enable = true;

  scripts = {
    dev.exec = "pnpm dev";
    build.exec = "pnpm build";
  };

  enterShell = ''
    echo "Web project: use 'dev' or 'pnpm dev'"
  '';
}
