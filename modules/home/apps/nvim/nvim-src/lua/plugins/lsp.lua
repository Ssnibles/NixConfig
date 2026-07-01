-- LSP configuration
local lsp = vim.lsp

-- Neovim 0.12 inlay-hint extmark workaround: clamp column to end of line.
if require("version") then
	if not vim.g.__inlay_hint_col_clamp then
		vim.g.__inlay_hint_col_clamp = true
		pcall(require, "vim.lsp.inlay_hint")
		local ns = vim.api.nvim_get_namespaces()["nvim.lsp.inlayhint"]
		if ns then
			local original_set_extmark = vim.api.nvim_buf_set_extmark
			vim.api.nvim_buf_set_extmark = function(bufnr, ns_id, line, col, opts)
				if ns_id == ns then
					local line_text = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
					if line_text then
						local max_col = #line_text
						if col > max_col then
							col = max_col
						elseif col < 0 then
							col = 0
						end
					end
				end
				return original_set_extmark(bufnr, ns_id, line, col, opts)
			end
		end
	end
end

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

	local fallback = (vim.env.HOME or "~") .. "/NixConfig"
	if vim.uv.fs_stat(fallback .. "/flake.nix") then
		return fallback
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
				("NIX_CONFIG_HOST=%s does not match flake hosts; falling back to auto-detection"):format(from_env),
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

	return hostname ~= "" and hostname or "desktop"
end

local function nix_string(value)
	local escaped = value:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("%${", "\\${")
	return ('"%s"'):format(escaped)
end

local function supports_lsp_rename(bufnr)
	local clients = vim.lsp.get_clients({
		bufnr = bufnr,
		method = "textDocument/rename",
	})
	return #clients > 0
end

local function prompt_lsp_rename()
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

local function open_literal_project_replace()
	local current_name = vim.fn.expand("<cword>")
	if current_name == "" then
		vim.notify("No word under cursor for literal replace", vim.log.levels.WARN)
		return
	end

	open_grug_far({
		search = current_name,
		flags = "--fixed-strings --word-regexp",
	})
end

local function open_regex_project_replace()
	local current_name = vim.fn.expand("<cword>")
	if current_name == "" then
		vim.notify("No word under cursor for regex replace", vim.log.levels.WARN)
		return
	end

	open_grug_far({
		search = ("\\b%s\\b"):format(escape_rg_regex(current_name)),
	})
end

local function smart_rename_replace()
	local bufnr = vim.api.nvim_get_current_buf()
	local has_lsp_rename = supports_lsp_rename(bufnr)
	local current_name = vim.fn.expand("<cword>")
	local has_word = current_name ~= ""

	local choices = {}
	if has_lsp_rename then
		choices[#choices + 1] = {
			label = "LSP symbol rename (context-aware, recommended)",
			action = prompt_lsp_rename,
		}
	end
	if has_word then
		choices[#choices + 1] = {
			label = "Project replace word (simple, literal whole-word)",
			action = open_literal_project_replace,
		}
		choices[#choices + 1] = {
			label = "Project replace regex (advanced patterns)",
			action = open_regex_project_replace,
		}
	end

	if #choices == 0 then
		vim.notify("No rename target: place cursor on a word or use an LSP-enabled buffer", vim.log.levels.WARN)
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

vim.api.nvim_create_user_command("SmartRename", smart_rename_replace, {
	desc = "Context-aware rename and project replace",
})

-- Fidget: LSP progress indicator
require("fidget").setup({
	progress = {
		suppress_on_insert = true,
		display = { done_icon = "✓", done_ttl = 2 },
	},
	notification = {
		filter = vim.log.levels.INFO,
		window = { winblend = 0, border = "none" },
	},
})

-- Tiny code action UI
require("tiny-code-action").setup({
	backend = "vim",
	picker = "fzf-lua",
})

-- Capabilities (enhanced by blink.cmp)
local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()
capabilities.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
capabilities.textDocument.semanticTokens = {
	requests = { range = true, full = { delta = true } },
}

-- Flake configuration for nixd
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
		nixos = {
			expr = ("(builtins.getFlake %s).nixosConfigurations.%s.options"):format(flake_ref, host_attr),
		},
		["home-manager"] = {
			expr = ('(builtins.getFlake %s).nixosConfigurations.%s.options."home-manager".users.type.getSubOptions []'):format(
				flake_ref,
				host_attr
			),
		},
	}
end

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
	map("K", lsp.buf.hover, "Hover documentation")
	map("<C-k>", lsp.buf.signature_help, "Signature help")
	map("<leader>rn", function()
		if not supports_lsp_rename(vim.api.nvim_get_current_buf()) then
			vim.notify("No attached LSP supports rename in this buffer", vim.log.levels.WARN)
			return
		end
		prompt_lsp_rename()
	end, "Rename symbol")
	map("<leader>ca", function()
		local ok, tiny = pcall(require, "tiny-code-action")
		if ok then
			tiny.code_action()
		else
			lsp.buf.code_action()
		end
	end, "Code action")
end

-- Global LSP config (applies to all servers)
lsp.config("*", {
	capabilities = capabilities,
	flags = { debounce_text_changes = 150 },
	on_attach = function(_, bufnr)
		attach_lsp_keymaps(bufnr)
	end,
})

-- Hover/signature handlers with rounded borders (without deprecated vim.lsp.with)
local function with_rounded_border(handler)
	return function(err, result, ctx, config)
		config = config or {}
		config.border = config.border or "rounded"
		return handler(err, result, ctx, config)
	end
end

lsp.handlers["textDocument/hover"] = with_rounded_border(lsp.handlers.hover)
lsp.handlers["textDocument/signatureHelp"] = with_rounded_border(lsp.handlers.signature_help)

-- Server configs
lsp.config("nixd", {
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
})

lsp.config("lua_ls", {
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
})

lsp.config("pyright", {
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
})

local ts_js_inlay_hints = {
	parameterNames = { enabled = "literals" },
	parameterTypes = { enabled = true },
	variableTypes = { enabled = true },
	propertyDeclarationTypes = { enabled = true },
	functionLikeReturnTypes = { enabled = true },
	enumMemberValues = { enabled = true },
}

local ts_js_settings = {
	suggest = { completeFunctionCalls = true },
	updateImportsOnFileMove = { enabled = "always" },
	inlayHints = ts_js_inlay_hints,
}

lsp.config("vtsls", {
	filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	settings = {
		vtsls = {
			autoUseWorkspaceTsdk = true,
			enableMoveToFileCodeAction = true,
		},
		typescript = vim.deepcopy(ts_js_settings),
		javascript = vim.deepcopy(ts_js_settings),
	},
})

lsp.config("kotlin_language_server", {
	filetypes = { "kotlin" },
	root_markers = { "settings.gradle.kts", "settings.gradle", "build.gradle.kts", "build.gradle", ".git" },
})

lsp.config("jdtls", {
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
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
				importOrder = {
					"java",
					"javax",
					"com",
					"org",
				},
			},
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = {
					useJava7Objects = true,
				},
				useBlocks = true,
			},
			configuration = {
				updateBuildConfiguration = "interactive",
			},
			saveActions = {
				organizeImports = false,
			},
			format = {
				enabled = true,
			},
			inlayHints = {
				parameterNames = {
					enabled = "all",
				},
			},
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
			inferSelectionSupport = {
				"extractMethod",
				"extractVariable",
				"extractConstant",
			},
		},
	},
})

lsp.config("marksman", {
	filetypes = { "markdown", "markdown.mdx" },
	root_markers = { "marksman.toml", ".git" },
})

lsp.config("ltex_plus", {
	cmd = { "ltex-ls-plus" },
	filetypes = { "tex", "latex", "bib", "markdown", "html", "org" },
	root_markers = { ".git" },
})

lsp.config("tinymist", {
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
					group = {
						{
							name = "primary",
							highlight = {
								background = "#ffcc00",
								foreground = "#000000",
							},
						},
					},
				},
			},
		},
	},
})

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

lsp.config("qml_language_server", {
	cmd = { "qml-language-server" },
	root_markers = { "qmldir", "shell.qml", ".git" },
	filetypes = { "qml", "qmljs" },
})

-- Roslyn (C#)
local ok_roslyn, roslyn = pcall(require, "roslyn")
if ok_roslyn then
	roslyn.setup({
		filewatching = "roslyn",
	})
end

lsp.config("roslyn", {
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
})

local managed_servers = {
	{ name = "nixd", cmd = "nixd" },
	{ name = "lua_ls", cmd = "lua-language-server" },
	{ name = "pyright", cmd = "pyright-langserver" },
	{ name = "vtsls", cmd = "vtsls" },
	{ name = "kotlin_language_server", cmd = "kotlin-language-server" },
	{ name = "jdtls", cmd = "jdtls" },
	{ name = "marksman", cmd = "marksman" },
	{ name = "ltex_plus", cmd = "ltex-ls-plus" },
	{ name = "tinymist", cmd = "tinymist" },
	{ name = "qml_language_server", cmd = "qml-language-server" },
}

for _, server in ipairs(managed_servers) do
	if vim.fn.executable(server.cmd) == 1 then
		lsp.enable(server.name)
	else
		vim.notify(("Skipped %s LSP: `%s` not found on PATH"):format(server.name, server.cmd), vim.log.levels.WARN)
	end
end

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

	local active = vim.lsp.get_clients({ bufnr = 0 })
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
