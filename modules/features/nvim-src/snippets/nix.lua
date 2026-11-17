local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("nix", {
	s({ trig = "module", desc = "NixOS Dendritic Module Template" }, {
		t({
			"{ ... }:",
			"{",
			"  nixos.modules.shared =",
			"    {",
			"      config,",
			"      lib,",
			"      pkgs,",
			"      ...",
			"    }:",
			"    let",
			"      cfg = config.features.",
		}),
		i(1, "feature"),
		t({ ";", "    in", "    {", "      options.features." }),
		i(2, "feature"),
		t({ ".enable = lib.mkEnableOption " }),
		i(3, '"enable this feature"'),
		t({ ";", "", "      config = lib.mkIf cfg.enable {", "        " }),
		i(4),
		t({ "", "      };", "    };", "}" }),
	}),

	s({ trig = "hjem-module", desc = "Hjem User Configuration Module Template" }, {
		t({
			"{ ... }:",
			"{",
			"  nixos.modules.shared =",
			"    {",
			"      config,",
			"      lib,",
			"      pkgs,",
			"      ...",
			"    }:",
			"    let",
			"      cfg = config.features.",
		}),
		i(1, "feature"),
		t({ ";", "    in", "    {", "      options.features." }),
		i(2, "feature"),
		t({ ".enable = lib.mkEnableOption " }),
		i(3, '"enable this feature"'),
		t({ ";", "", "      config = lib.mkIf cfg.enable {", '        hjem.users."${config.username}".files."' }),
		i(4, ".config/app/config"),
		t({ '" = {', "          text = ''", "            " }),
		i(5),
		t({ "", "          '';", "        };", "      };", "    };", "}" }),
	}),

	s({ trig = "pkg", desc = "Nix Package (stdenv.mkDerivation)" }, {
		t({ "{ lib, stdenv, fetchFromGitHub, ... }:", "", "stdenv.mkDerivation rec {", '  pname = "' }),
		i(1, "name"),
		t({ '";', '  version = "' }),
		i(2, "0.1.0"),
		t({ '";', "", "  src = fetchFromGitHub {", '    owner = "' }),
		i(3, "owner"),
		t({ '";', "    repo = pname;", '    rev = "v${version}";', '    hash = "' }),
		i(4, "sha256-..."),
		t({ '";', "  };", "", "  meta = with lib; {", '    description = "' }),
		i(5, "Description"),
		t({ '";', '    homepage = "' }),
		i(6, "https://github.com/..."),
		t({ '";', "    license = licenses.mit;", "    maintainers = [ ];", "  };", "}" }),
	}),

	s({ trig = "shell", desc = "Nix Developer Shell (mkShell)" }, {
		t({ "{ pkgs ? import <nixpkgs> {} }:", "", "pkgs.mkShell {", "  nativeBuildInputs = with pkgs; [", "    " }),
		i(1, "build-tools"),
		t({ "", "  ];", "", "  shellHook = ''", "    " }),
		i(2, "echo 'Developer shell active'"),
		t({ "", "  '';", "}" }),
	}),

	s({ trig = "writeShellScriptBin", desc = "writeShellScriptBin script wrapper" }, {
		t('(pkgs.writeShellScriptBin "'),
		i(1, "name"),
		t({ "\" ''", "  " }),
		i(2, "set -euo pipefail"),
		t({ "", "  " }),
		i(3),
		t({ "", "''" }),
		t(")"),
	}),
})
