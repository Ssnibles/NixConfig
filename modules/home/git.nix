# =============================================================================
# Git Configuration
# =============================================================================
{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Ssnibles";
        email = "joshua.breite@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta = {
        navigate = true;
        side-by-side = true;
        line-numbers = true;
      };
    };
    signing.format = null;
  };
}
