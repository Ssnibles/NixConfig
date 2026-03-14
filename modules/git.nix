{ ... }: {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ssnibles";
        email = "joshua.breite@gmail.com";
      };
      init.defaultBranch = "main";
      # Rebase instead of merge on pull — keeps history linear.
      pull.rebase = true;
    };
  };
}
