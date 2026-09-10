-- =============================================================================
-- LSP SERVER DEFINITIONS (pure data — no side effects)
-- =============================================================================
-- Each key is the server name recognized by vim.lsp.config().
-- Values are configuration tables passed to register_server() in lsp/init.lua.
-- =============================================================================

local lsp = vim.lsp

-- ── Nix helpers ──────────────────────────────────────────────────────

local NIX_FALLBACK_DIR = (vim.env.HOME or "~") .. "/NixConfig"
local NIX_DEFAULT_HOST = "desktop"

local function detect_flake_root()
	local from_env = vim.env.NIX_CONFIG_FLAKE
	if from_env and from_env ~= "" then
		local root = from_env:gsub("/flake.nix$", "")
		if vim.uv.fs_stat(root .. "/flake.nix") then
			return root
		end
	end
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	local flake = vim.fs.find("flake.nix", { path = cwd, upward = true })[1]
	if flake then
		return vim.fs.dirname(flake)
	end
	if vim.uv.fs_stat(NIX_FALLBACK_DIR .. "/flake.nix") then
		return NIX_FALLBACK_DIR
	end
	return nil
end

local function host_exists(root, host)
	return root and host ~= "" and vim.uv.fs_stat(("%s/hosts/%s"):format(root, host)) ~= nil
end

local function detect_nix_host(root)
	local from_env = vim.env.NIX_CONFIG_HOST
	if from_env and from_env ~= "" then
		if not root or host_exists(root, from_env) then
			return from_env
		end
	end
	local hostname = (vim.uv.os_gethostname() or ""):match("^[^.]+") or ""
	if hostname ~= "" and host_exists(root, hostname) then return hostname end
	if host_exists(root, "desktop") then return "desktop" end
	if host_exists(root, "laptop") then return "laptop" end
	return hostname ~= "" and hostname or NIX_DEFAULT_HOST
end

local function nix_string(value)
	return ('"%s"'):format(value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("%${", "\\${"))
end

local function get_nixd_config()
	local root = detect_flake_root()
	local host = detect_nix_host(root)
	local ref = root and nix_string(root) or nil
	local attr = nix_string(host)

	local nixpkgs_expr = "import <nixpkgs> {}"
	local options = {}
	if ref then
		nixpkgs_expr = ([[
let
  flake = builtins.getFlake %s;
  system = builtins.currentSystem;
  pkgs = import flake.inputs.nixpkgs { inherit system; config = { allowUnfree = true; }; };
  unstable = import flake.inputs."nixpkgs-unstable" { inherit system; config = { allowUnfree = true; }; };
in
  pkgs // { unstable = unstable; }
]]):format(ref)

		options = {
			nixos = { expr = ("(builtins.getFlake %s).nixosConfigurations.%s.options"):format(ref, attr) },
			["home-manager"] = {
				expr = ('(builtins.getFlake %s).nixosConfigurations.%s.options."home-manager".users.type.getSubOptions []'):format(ref, attr),
			},
		}
	end

	return {
		cmd = { "nixd" },
		filetypes = { "nix" },
		root_markers = { "flake.nix", ".git" },
		settings = {
			nixd = {
				nixpkgs = { expr = nixpkgs_expr },
				formatting = { command = { "nixfmt" } },
				options = options,
			},
		},
	}
end

-- ── Blink.cmp capabilities (for servers needing extra) ───────────────

local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()

-- ── Server table ─────────────────────────────────────────────────────

return {
	-- Nix
	nixd = get_nixd_config,

	-- Lua
	lua_ls = {
		cmd = { "lua-language-server" },
		filetypes = { "lua" },
		root_markers = { ".luarc.json", ".stylua.toml", "flake.nix", ".git" },
		settings = {
			Lua = {
				hint = { enable = true, arrayIndex = "Disable" },
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				completion = { callSnippet = "Replace" },
				workspace = {
					checkThirdParty = false,
					library = { [vim.env.VIMRUNTIME] = true, [vim.fn.stdpath("config")] = true },
				},
				telemetry = { enable = false },
			},
		},
	},

	-- Python
	pyright = {
		exe = "pyright-langserver",
		filetypes = { "python" },
		root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
		settings = {
			python = {
				analysis = {
					autoImportCompletions = true, autoSearchPaths = true,
					diagnosticMode = "openFilesOnly", typeCheckingMode = "basic",
					useLibraryCodeForTypes = true,
				},
			},
		},
	},

	-- HTML
	html = {
		cmd = { "vscode-html-language-server", "--stdio" },
		filetypes = { "html", "templ" },
		root_markers = { "package.json", ".git" },
	},

	-- CSS
	cssls = {
		cmd = { "vscode-css-language-server", "--stdio" },
		filetypes = { "css", "scss", "less" },
		root_markers = { "package.json", ".git" },
		settings = { css = { validate = true }, scss = { validate = true }, less = { validate = true } },
	},

	-- Emmet
	emmet_ls = {
		cmd = { "emmet-ls", "--stdio" },
		filetypes = { "html", "css", "scss", "less", "javascriptreact", "typescriptreact", "vue", "svelte", "astro", "templ" },
		root_markers = { "package.json", ".git" },
		init_options = { html = { options = { ["bem.enabled"] = true, ["output.indent"] = "  " } } },
	},

	-- ESLint
	eslint = {
		cmd = { "vscode-eslint-language-server", "--stdio" },
		filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue", "svelte", "astro" },
		root_markers = {
			".eslintrc", ".eslintrc.js", ".eslintrc.cjs", ".eslintrc.json", ".eslintrc.yml", ".eslintrc.yaml",
			"eslint.config.js", "eslint.config.mjs", "eslint.config.cjs", "eslint.config.ts", "package.json", ".git",
		},
		settings = {
			validate = "on", packageManager = "npm", useESLintClass = false,
			experimental = { useFlatConfig = false }, codeActionOnSave = { enable = false, mode = "all" },
			format = true, quiet = false, onIgnoredFiles = "off", rulesCustomizations = {},
			run = "onType", problems = { shortenToSingleLine = false }, nodePath = "",
			workingDirectory = { mode = "location" },
		},
	},

	-- JSON
	jsonls = {
		cmd = { "vscode-json-language-server", "--stdio" },
		filetypes = { "json", "jsonc" },
		root_markers = { "package.json", ".git" },
	},

	-- Kotlin
	kotlin_language_server = {
		exe = "kotlin-language-server",
		filetypes = { "kotlin" },
		root_markers = { "settings.gradle.kts", "settings.gradle", "build.gradle.kts", "build.gradle", ".git" },
	},

	-- Java
	jdtls = {
		cmd = { "jdtls" },
		filetypes = { "java" },
		root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", ".git" },
		settings = {
			java = {
				signatureHelp = { enabled = true },
				contentProvider = { preferred = "fernflower" },
				completion = {
					favoriteStaticMembers = {
						"org.hamcrest.MatcherAssert.assertThat", "org.hamcrest.Matchers.*", "org.hamcrest.CoreMatchers.*",
						"org.junit.jupiter.api.Assertions.*", "java.util.Objects.requireNonNull",
						"java.util.Objects.requireNonNullElse", "org.mockito.Mockito.*",
					},
					filteredTypes = { "com.sun.*", "io.micrometer.shaded.*", "java.awt.*", "jdk.*", "sun.*" },
					importOrder = { "java", "javax", "com", "org" },
				},
				sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
				codeGeneration = {
					toString = { template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}" },
					hashCodeEquals = { useJava7Objects = true }, useBlocks = true,
				},
				configuration = { updateBuildConfiguration = "interactive" },
				saveActions = { organizeImports = false },
				format = { enabled = true },
				inlayHints = { parameterNames = { enabled = "all" } },
			},
		},
		init_options = {
			extendedClientCapabilities = {
				progressReportProvider = true, classFileContentsSupport = true,
				generateToStringPromptSupport = true, hashCodeEqualsPromptSupport = true,
				advancedOrganizeImportsSupport = true, advancedGenerateAccessorsSupport = true,
				advancedExtractRefactoringSupport = true, moveRefactoringSupport = true,
				inferSelectionSupport = { "extractMethod", "extractVariable", "extractConstant" },
			},
		},
	},

	-- Markdown
	marksman = {
		exe = "marksman",
		filetypes = { "markdown", "markdown.mdx" },
		root_markers = { "marksman.toml", ".git" },
	},

	-- LaTeX / Text
	ltex_plus = {
		cmd = { "ltex-ls-plus" },
		filetypes = { "tex", "latex", "bib", "markdown", "org" },
		root_markers = { ".git" },
	},

	-- Typst
	tinymist = {
		cmd = { "tinymist" },
		filetypes = { "typst" },
		root_markers = { ".git" },
		settings = {
			tinymist = {
				exportPdf = "onType", formatterMode = "typstyle",
				preview = {
					scrollSync = "onSelectionChangeByCursor",
					cursor = { group = { { name = "primary", highlight = { background = "#ffcc00", foreground = "#000000" } } } },
				},
			},
		},
	},

	-- QML
	qmlls = {
		exe = "qmlls",
		filetypes = { "qml" },
		root_markers = { ".qmlls.ini", "shell.qml", "qmldir", ".git" },
	},

	-- Zig
	zls = {
		cmd = { "zls" },
		filetypes = { "zig", "zir" },
		root_markers = { "build.zig", "zls.json", ".git" },
		settings = {
			zls = {
				enable_inlay_hints = true, enable_snippets = true, warn_style = true,
				enable_build_on_save = true, build_on_save_step = "check",
				enable_autofix = true, enable_import_embedfile = true,
			},
		},
	},

	-- C# (Roslyn)
	roslyn = {
		exe = "Microsoft.CodeAnalysis.LanguageServer",
		settings = {
			["csharp|background_analysis"] = { dotnet_analyzer_diagnostics_scope = "openFiles", dotnet_compiler_diagnostics_scope = "openFiles" },
			["csharp|completion"] = { dotnet_show_name_completion_suggestions = true, dotnet_show_completion_items_from_unimported_namespaces = true, dotnet_provide_regex_completions = false },
			["csharp|inlay_hints"] = {
				csharp_enable_inlay_hints_for_implicit_object_creation = true,
				csharp_enable_inlay_hints_for_implicit_variable_types = true,
				csharp_enable_inlay_hints_for_lambda_parameter_types = true,
				csharp_enable_inlay_hints_for_types = true,
				dotnet_enable_inlay_hints_for_parameters = true,
				dotnet_enable_inlay_hints_for_object_creation_parameters = true,
				dotnet_enable_inlay_hints_for_other_parameters = true,
				dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
				dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
			},
			["csharp|code_lens"] = { dotnet_enable_references_code_lens = true, dotnet_enable_tests_code_lens = true },
			["csharp|symbol_search"] = { dotnet_search_reference_assemblies = false },
			["csharp|formatting"] = { dotnet_organize_imports_on_format = true },
		},
	},

	-- C / C++ (clangd)
	clangd = {
		cmd = {
			"clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu",
			"--completion-style=detailed", "--function-arg-placeholders", "--fallback-style=llvm",
			"--query-driver=/**/*", "--all-scopes-completion", "--suggest-missing-includes", "--cross-file-rename",
		},
		filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
		root_markers = {
			".clangd", ".clang-format", ".clang-tidy", "compile_commands.json", "compile_flags.txt",
			"CMakeLists.txt", "Makefile", "meson.build", "build.ninja", "flake.nix", ".git",
		},
		capabilities = vim.tbl_deep_extend("force", capabilities, { offsetEncoding = { "utf-16" } }),
		on_new_config = function(new_config, _)
			local ok_c, c_mod = pcall(require, "plugins.lang")
			local flags
			if ok_c and type(c_mod.get_nix_c_flags) == "function" then
				flags = c_mod.get_nix_c_flags()
			else
				flags = { "-std=c11", "-Wall", "-Wextra" }
			end
			new_config.init_options = new_config.init_options or {}
			new_config.init_options.fallbackFlags = flags
		end,
	},
}
