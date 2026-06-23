{ inputs, vimUtils, fetchFromGitHub }:

vimUtils.buildVimPlugin {
  pname = "tiny-code-action";
  version = "main";
  src = fetchFromGitHub {
    owner = "rachartier";
    repo = "tiny-code-action.nvim";
    rev = "main";
    sha256 = "sha256-UF9zeO5Uujdt2MEwy2d2Lhk6JRnEN4vrEvYslv0/zaA=";
  };
  doCheck = false;
}
