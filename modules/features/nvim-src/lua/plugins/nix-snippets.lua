local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local sn = ls.snippet_node

ls.add_snippets("nix", {
	s({ trig = "module", desc = "NixOS Module Template" }, {
		t({ "{ config, lib, pkgs, ... }:", "", "with lib;", "let", "  cfg = config.modules." }),
		i(1, "feature"),
		t({ ";", "in {", "  options.modules." }),
		i(2, "feature"),
		t({ " = {", "    enable = mkEnableOption " }),
		i(3, '"enable this feature"'),
		t({ ";", "  };", "", "  config = mkIf cfg.enable {", "    " }),
		i(4),
		t({ "", "  };", "}" }),
	}),

	s({ trig = "hm-module", desc = "Home Manager Module Template" }, {
		t({ "{ config, lib, pkgs, ... }:", "", "with lib;", "let", "  cfg = config.home.modules." }),
		i(1, "feature"),
		t({ ";", "in {", "  options.home.modules." }),
		i(2, "feature"),
		t({ " = {", "    enable = mkEnableOption " }),
		i(3, '"enable this feature"'),
		t({ ";", "  };", "", "  config = mkIf cfg.enable {", "    " }),
		i(4),
		t({ "", "  };", "}" }),
	}),

	s({ trig = "pkg", desc = "Nix Package (stdenv.mkDerivation)" }, {
		t({ "{ lib, stdenv, fetchFromGitHub, ... }:", "", "stdenv.mkDerivation rec {", "  pname = \"" }),
		i(1, "name"),
		t({ "\";", "  version = \"" }),
		i(2, "0.1.0"),
		t({ "\";", "", "  src = fetchFromGitHub {", "    owner = \"" }),
		i(3, "owner"),
		t({ "\";", "    repo = pname;", "    rev = \"v${version}\";", "    hash = \"" }),
		i(4, "sha256-..."),
		t({ "\";", "  };", "", "  meta = with lib; {", "    description = \"" }),
		i(5, "Description"),
		t({ "\";", "    homepage = \"" }),
		i(6, "https://github.com/..."),
		t({ "\";", "    license = licenses.mit;", "    maintainers = [ ];", "  };", "}" }),
	}),

	s({ trig = "shell", desc = "Nix Developer Shell (mkShell)" }, {
		t({ "{ pkgs ? import <nixpkgs> {} }:", "", "pkgs.mkShell {", "  nativeBuildInputs = with pkgs; [", "    " }),
		i(1, "build-tools"),
		t({ "", "  ];", "", "  shellHook = ''", "    " }),
		i(2, "echo 'Developer shell active'"),
		t({ "", "  '';", "}" }),
	}),

	s({ trig = "writeShellScriptBin", desc = "writeShellScriptBin script wrapper" }, {
		t("(pkgs.writeShellScriptBin \""),
		i(1, "name"),
		t({ "\" ''", "  " }),
		i(2, "#!/usr/bin/env bash"),
		t({ "", "  " }),
		i(3),
		t({ "", "''" }),
		t(")"),
	}),
})
