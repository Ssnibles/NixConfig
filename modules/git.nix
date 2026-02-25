{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ssnibles";
        email = "joshua.breite@gmail.com";
      };
      init.defaultBranch = "main";
    };
  };
}
