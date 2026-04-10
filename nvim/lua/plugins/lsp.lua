-- LSP configuration
local lsp = vim.lsp

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

	local hostname = vim.loop.os_gethostname() or ""
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
			expr = ("(builtins.getFlake %s).nixosConfigurations.%s.options.\"home-manager\".users.type.getSubOptions []"):format(
				flake_ref,
				host_attr
			),
		},
	}
end

-- Global LSP config (applies to all servers)
lsp.config("*", {
	capabilities = capabilities,
	flags = { debounce_text_changes = 150 },
	on_attach = function(client, bufnr)
		if client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		if not vim.b[bufnr]._lsp_keymaps_attached then
			vim.b[bufnr]._lsp_keymaps_attached = true

			local map = function(keys, fn, desc)
				vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
			end

			map("gd", lsp.buf.definition, "Go to definition")
			map("gD", lsp.buf.declaration, "Go to declaration")
			map("gi", lsp.buf.implementation, "Go to implementation")
			map("gr", lsp.buf.references, "Find references")
			map("K", lsp.buf.hover, "Hover documentation")
			map("<leader>rn", lsp.buf.rename, "Rename symbol")
			map("<leader>ca", function()
				local ok, tiny = pcall(require, "tiny-code-action")
				if ok then
					tiny.code_action()
				else
					lsp.buf.code_action()
				end
			end, "Code action")
		end
	end,
})

-- Hover with rounded borders
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })
lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, { border = "rounded" })

-- Server configs
lsp.config("nixd", {
	cmd = { "nixd" },
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

lsp.config("vtsls", {
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	settings = {
		vtsls = {
			autoUseWorkspaceTsdk = true,
			enableMoveToFileCodeAction = true,
		},
		typescript = {
			suggest = { completeFunctionCalls = true },
			updateImportsOnFileMove = { enabled = "always" },
			inlayHints = {
				parameterNames = { enabled = "literals" },
				parameterTypes = { enabled = true },
				variableTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				enumMemberValues = { enabled = true },
			},
		},
		javascript = {
			suggest = { completeFunctionCalls = true },
			updateImportsOnFileMove = { enabled = "always" },
			inlayHints = {
				parameterNames = { enabled = "literals" },
				parameterTypes = { enabled = true },
				variableTypes = { enabled = true },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = true },
				enumMemberValues = { enabled = true },
			},
		},
	},
})

lsp.config("kotlin_language_server", {
	root_markers = { "settings.gradle.kts", "settings.gradle", "build.gradle.kts", "build.gradle", ".git" },
})

lsp.config("jdtls", {
	root_markers = { "pom.xml", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", ".git" },
})

lsp.config("marksman", {
	root_markers = { "marksman.toml", ".git" },
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

-- Enable servers
local server_cmd = {
	nixd = "nixd",
	lua_ls = "lua-language-server",
	pyright = "pyright-langserver",
	vtsls = "vtsls",
	kotlin_language_server = "kotlin-language-server",
	jdtls = "jdtls",
	marksman = "marksman",
}

local configured_servers = { "nixd", "lua_ls", "pyright", "vtsls", "kotlin_language_server", "jdtls", "marksman" }
for _, server in ipairs(configured_servers) do
	local cmd = server_cmd[server]
	if not cmd or vim.fn.executable(cmd) == 1 then
		lsp.enable(server)
	else
		vim.notify(("Skipped %s LSP: `%s` not found on PATH"):format(server, cmd), vim.log.levels.WARN)
	end
end

vim.api.nvim_create_user_command("LspHealth", function()
	local lines = { "LSP Health" }
	for _, server in ipairs(configured_servers) do
		local cmd = server_cmd[server]
		if not cmd then
			lines[#lines + 1] = ("- %s: command unknown"):format(server)
		else
			local exe = vim.fn.exepath(cmd)
			if exe ~= "" then
				lines[#lines + 1] = ("- %s: OK (%s)"):format(server, exe)
			else
				lines[#lines + 1] = ("- %s: missing `%s`"):format(server, cmd)
			end
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
