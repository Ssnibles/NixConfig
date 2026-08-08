-- =============================================================================
-- LSP CONFIGURATION & EASY SERVER REGISTRATION
-- =============================================================================

-- Global UI & Nix Environment Configuration
local CONFIG = {
	ui = {
		border = "rounded",
		max_width_ratio = 0.6,
		max_height_ratio = 0.4,
	},

	nix = {
		fallback_dir = (vim.env.HOME or "~") .. "/NixConfig",
		default_host = "desktop",
	},
}

local lsp = vim.lsp

-- Triggers LSP hover documentation with standard window dimensions and borders
local function show_hover_doc()
	lsp.buf.hover({
		border = CONFIG.ui.border,
		max_width = math.floor(vim.o.columns * CONFIG.ui.max_width_ratio),
		max_height = math.floor(vim.o.lines * CONFIG.ui.max_height_ratio),
	})
end

-- Builds client capabilities including blink.cmp completions, folding ranges, and semantic tokens
local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()
capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
capabilities.textDocument.semanticTokens = { requests = { range = true, full = { delta = true } } }

-- Forward references for rename prompt functions
local supports_lsp_rename, prompt_lsp_rename

-- Binds LSP navigation and refactoring keymaps to a specific buffer
local function attach_lsp_keymaps(bufnr)
	if vim.b[bufnr]._lsp_keymaps_attached then
		return
	end
	vim.b[bufnr]._lsp_keymaps_attached = true

	local map = function(keys, fn, desc)
		vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
	end

	map("gd", lsp.buf.definition, "Go to definition")
	map("gD", lsp.buf.declaration, "Go to declaration")
	map("gi", lsp.buf.implementation, "Go to implementation")
	map("gr", function()
		require("fzf-lua").lsp_references({ jump_to_single_result = true })
	end, "Find references")
	map("K", show_hover_doc, "Hover documentation")
	map("L", lsp.buf.signature_help, "Signature help")
	map("<leader>rn", function()
		if not supports_lsp_rename(vim.api.nvim_get_current_buf()) then
			vim.notify("No attached LSP supports rename in this buffer", vim.log.levels.WARN)
			return
		end
		prompt_lsp_rename()
	end, "Rename symbol")
	map("<leader>ca", lsp.buf.code_action, "Code action")
end

-- Global LSP defaults automatically applied to all servers
lsp.config("*", {
	capabilities = capabilities,
	flags = { debounce_text_changes = 150 },
	on_attach = function(_, bufnr)
		attach_lsp_keymaps(bufnr)
	end,
})

-- Track managed server statuses for :LspHealth
local managed_servers = {}

--- Registers and enables an LSP server if its binary executable exists on PATH.
--- Automatically applies standard capabilities, keymaps, and configuration.
--- @param name string Server name recognized by Neovim or custom name
--- @param config table|function Server configuration table or generator function returning table
local function register_server(name, config)
	if type(config) == "function" then
		config = config()
	end
	config = config or {}

	-- Determine executable binary name: explicit `exe` -> `cmd` -> server `name`
	local cmd = config.cmd
	local exe = config.exe
	if not exe then
		if type(cmd) == "table" and cmd[1] then
			exe = cmd[1]
		elseif type(cmd) == "string" then
			exe = cmd
		else
			exe = name
		end
	end

	local lsp_opts = vim.deepcopy(config)
	lsp_opts.exe = nil -- Remove custom helper property before passing to lsp.config

	local is_exec = vim.fn.executable(exe) == 1
	table.insert(managed_servers, { name = name, cmd = exe, active = is_exec })

	if is_exec then
		if next(lsp_opts) ~= nil then
			lsp.config(name, lsp_opts)
		end
		lsp.enable(name)
	else
		vim.notify(("Skipped %s LSP: `%s` not found on PATH"):format(name, exe), vim.log.levels.WARN)
	end
end

-- =============================================================================
-- NIX CONFIGURATION HELPERS
-- =============================================================================

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

	if vim.uv.fs_stat(CONFIG.nix.fallback_dir .. "/flake.nix") then
		return CONFIG.nix.fallback_dir
	end

	return nil
end

local function host_exists(flake_root, host)
	if not flake_root or host == "" then
		return false
	end
	return vim.uv.fs_stat(("%s/hosts/%s"):format(flake_root, host)) ~= nil
end

local function detect_nix_host(flake_root)
	local from_env = vim.env.NIX_CONFIG_HOST
	if from_env and from_env ~= "" then
		if not flake_root or host_exists(flake_root, from_env) then
			return from_env
		end
		vim.schedule(function()
			vim.notify(
				("NIX_CONFIG_HOST=%s does not match flake hosts; falling back"):format(from_env),
				vim.log.levels.WARN
			)
		end)
	end

	local hostname = vim.uv.os_gethostname() or ""
	local short_hostname = hostname:match("^[^.]+") or hostname
	if short_hostname ~= "" and host_exists(flake_root, short_hostname) then
		return short_hostname
	end

	if host_exists(flake_root, "desktop") then
		return "desktop"
	end
	if host_exists(flake_root, "laptop") then
		return "laptop"
	end

	return hostname ~= "" and hostname or CONFIG.nix.default_host
end

local function nix_string(value)
	local escaped = value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("%${", "\\${")
	return ('"%s"'):format(escaped)
end

local function get_nixd_config()
	local flake_root = detect_flake_root()
	local nix_host = detect_nix_host(flake_root)
	local flake_ref = flake_root and nix_string(flake_root) or nil
	local host_attr = nix_string(nix_host)

	local nixpkgs_expr = "import <nixpkgs> {}"
	local nixd_options = {}
	if flake_ref then
		nixpkgs_expr = ([[
let
  flake = builtins.getFlake %s;
  system = builtins.currentSystem;
  pkgs = import flake.inputs.nixpkgs { inherit system; };
  unstable = import flake.inputs."nixpkgs-unstable" { inherit system; };
in
  pkgs // { unstable = unstable; }
]]):format(flake_ref)

		nixd_options = {
			nixos = { expr = ("(builtins.getFlake %s).nixosConfigurations.%s.options"):format(flake_ref, host_attr) },
			["home-manager"] = {
				expr = ('(builtins.getFlake %s).nixosConfigurations.%s.options."home-manager".users.type.getSubOptions []'):format(
					flake_ref,
					host_attr
				),
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
				options = nixd_options,
			},
		},
	}
end

-- =============================================================================
-- REGISTERED LANGUAGE SERVERS
-- Add or modify language servers here!
-- Each server defined here is automatically checked on PATH, configured,
-- enabled, and equipped with standard capabilities & keymaps.
-- =============================================================================

local SERVERS = {
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
					library = {
						[vim.env.VIMRUNTIME] = true,
						[vim.fn.stdpath("config")] = true,
					},
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
					autoImportCompletions = true,
					autoSearchPaths = true,
					diagnosticMode = "openFilesOnly",
					typeCheckingMode = "basic",
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
		settings = {
			css = { validate = true },
			scss = { validate = true },
			less = { validate = true },
		},
	},

	-- ESLint
	eslint = {
		cmd = { "vscode-eslint-language-server", "--stdio" },
		filetypes = {
			"javascript",
			"javascriptreact",
			"javascript.jsx",
			"typescript",
			"typescriptreact",
			"typescript.tsx",
			"vue",
			"svelte",
			"astro",
		},
		root_markers = {
			".eslintrc",
			".eslintrc.js",
			".eslintrc.cjs",
			".eslintrc.json",
			".eslintrc.yml",
			".eslintrc.yaml",
			"eslint.config.js",
			"eslint.config.mjs",
			"eslint.config.cjs",
			"eslint.config.ts",
			"package.json",
			".git",
		},
		settings = {
			validate = "on",
			packageManager = "npm",
			useESLintClass = false,
			experimental = { useFlatConfig = false },
			codeActionOnSave = { enable = false, mode = "all" },
			format = true,
			quiet = false,
			onIgnoredFiles = "off",
			rulesCustomizations = {},
			run = "onType",
			problems = { shortenToSingleLine = false },
			nodePath = "",
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
						"org.hamcrest.MatcherAssert.assertThat",
						"org.hamcrest.Matchers.*",
						"org.hamcrest.CoreMatchers.*",
						"org.junit.jupiter.api.Assertions.*",
						"java.util.Objects.requireNonNull",
						"java.util.Objects.requireNonNullElse",
						"org.mockito.Mockito.*",
					},
					filteredTypes = { "com.sun.*", "io.micrometer.shaded.*", "java.awt.*", "jdk.*", "sun.*" },
					importOrder = { "java", "javax", "com", "org" },
				},
				sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
				codeGeneration = {
					toString = { template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}" },
					hashCodeEquals = { useJava7Objects = true },
					useBlocks = true,
				},
				configuration = { updateBuildConfiguration = "interactive" },
				saveActions = { organizeImports = false },
				format = { enabled = true },
				inlayHints = { parameterNames = { enabled = "all" } },
			},
		},
		init_options = {
			extendedClientCapabilities = {
				progressReportProvider = true,
				classFileContentsSupport = true,
				generateToStringPromptSupport = true,
				hashCodeEqualsPromptSupport = true,
				advancedOrganizeImportsSupport = true,
				advancedGenerateAccessorsSupport = true,
				advancedExtractRefactoringSupport = true,
				moveRefactoringSupport = true,
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
		filetypes = { "tex", "latex", "bib", "markdown", "html", "org" },
		root_markers = { ".git" },
	},

	-- Typst
	tinymist = {
		cmd = { "tinymist" },
		filetypes = { "typst" },
		root_markers = { ".git" },
		settings = {
			tinymist = {
				exportPdf = "onType",
				formatterMode = "typstyle",
				preview = {
					scrollSync = "onSelectionChangeByCursor",
					cursor = {
						group = { { name = "primary", highlight = { background = "#ffcc00", foreground = "#000000" } } },
					},
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

	-- C# (Roslyn)
	roslyn = {
		settings = {
			["csharp|background_analysis"] = {
				dotnet_analyzer_diagnostics_scope = "openFiles",
				dotnet_compiler_diagnostics_scope = "openFiles",
			},
			["csharp|completion"] = {
				dotnet_show_name_completion_suggestions = true,
				dotnet_show_completion_items_from_unimported_namespaces = true,
				dotnet_provide_regex_completions = false,
			},
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
			["csharp|code_lens"] = {
				dotnet_enable_references_code_lens = false,
				dotnet_enable_tests_code_lens = false,
			},
			["csharp|symbol_search"] = {
				dotnet_search_reference_assemblies = false,
			},
			["csharp|formatting"] = {
				dotnet_organize_imports_on_format = true,
			},
		},
	},
}

-- Execute server registrations
for name, config in pairs(SERVERS) do
	register_server(name, config)
end

-- Export register_server function globally so external plugins or configs can easily add servers
vim.g.register_lsp_server = register_server

-- =============================================================================
-- SEARCH & RENAME HELPERS & USER COMMANDS
-- =============================================================================

supports_lsp_rename = function(bufnr)
	local clients = lsp.get_clients({ bufnr = bufnr })
	for _, client in ipairs(clients) do
		if client:supports_method("textDocument/rename", bufnr) then
			return true
		end
	end
	return false
end

prompt_lsp_rename = function()
	local current_name = vim.fn.expand("<cword>")
	if current_name == "" then
		lsp.buf.rename()
		return
	end

	vim.ui.input({ prompt = "Rename symbol to: ", default = current_name }, function(new_name)
		if new_name == nil or new_name == "" or new_name == current_name then
			return
		end
		lsp.buf.rename(new_name)
	end)
end

local function escape_rg_regex(text)
	return text:gsub("([%(%)%.%+%-%*%?%[%]%^%$%{%}%|\\])", "\\%1")
end

local function open_grug_far(prefills)
	local ok, grug = pcall(require, "grug-far")
	if not ok then
		vim.notify("grug-far.nvim is not available", vim.log.levels.ERROR)
		return
	end

	local instance = grug.open({ prefills = prefills })
	if instance and type(instance.when_ready) == "function" and type(instance.goto_input) == "function" then
		instance:when_ready(function()
			instance:goto_input("replacement")
		end)
	end
end

local function smart_rename_replace()
	local bufnr = vim.api.nvim_get_current_buf()
	local has_lsp_rename = supports_lsp_rename(bufnr)
	local current_name = vim.fn.expand("<cword>")
	local has_word = current_name ~= ""

	local choices = {}
	if has_lsp_rename then
		choices[#choices + 1] = { label = "LSP symbol rename (recommended)", action = prompt_lsp_rename }
	end
	if has_word then
		choices[#choices + 1] = {
			label = "Project replace word (literal)",
			action = function()
				open_grug_far({ search = current_name, flags = "--fixed-strings --word-regexp" })
			end,
		}
		choices[#choices + 1] = {
			label = "Project replace regex",
			action = function()
				open_grug_far({ search = ("\\b%s\\b"):format(escape_rg_regex(current_name)) })
			end,
		}
	end

	if #choices == 0 then
		vim.notify("No rename target: place cursor on a word", vim.log.levels.WARN)
		return
	end
	if #choices == 1 then
		choices[1].action()
		return
	end

	vim.ui.select(choices, {
		prompt = "Rename/replace mode:",
		format_item = function(item)
			return item.label
		end,
	}, function(choice)
		if choice then
			choice.action()
		end
	end)
end

vim.api.nvim_create_user_command("SmartRename", smart_rename_replace, { desc = "Context-aware rename and replace" })

-- Displays LSP executable status on PATH and active clients for current buffer
vim.api.nvim_create_user_command("LspHealth", function()
	local lines = { "LSP Health" }
	for _, server in ipairs(managed_servers) do
		local exe = vim.fn.exepath(server.cmd)
		if exe ~= "" then
			lines[#lines + 1] = ("- %s: OK (%s)"):format(server.name, exe)
		else
			lines[#lines + 1] = ("- %s: missing `%s`"):format(server.name, server.cmd)
		end
	end

	local active = lsp.get_clients({ bufnr = 0 })
	if #active > 0 then
		local names = {}
		for _, client in ipairs(active) do
			names[#names + 1] = client.name
		end
		lines[#lines + 1] = ("Active in current buffer: %s"):format(table.concat(names, ", "))
	else
		lines[#lines + 1] = "Active in current buffer: none"
	end

	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "LSP Health" })
end, { desc = "Show LSP health details" })

-- =============================================================================
-- THIRD-PARTY PLUGIN SETUPS
-- =============================================================================

local ok_typst_preview, typst_preview = pcall(require, "typst-preview")
if ok_typst_preview then
	typst_preview.setup({
		get_root = function(path_of_main_file)
			local root = os.getenv("TYPST_ROOT")
			if root then
				return root
			end
			return vim.fn.fnamemodify(path_of_main_file, ":h")
		end,
	})
end

local ok_roslyn, roslyn = pcall(require, "roslyn")
if ok_roslyn then
	roslyn.setup({ filewatching = "roslyn" })
end
