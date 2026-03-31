# =============================================================================
# Git Configuration
# =============================================================================
{ ... }:
{
  programs.git = {
    enable = true;
    userName = "Ssnibles";
    userEmail = "joshua.breite@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
