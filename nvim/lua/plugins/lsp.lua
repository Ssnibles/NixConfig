-- LSP configuration
local lsp = vim.lsp

local function detect_nix_host()
	local from_env = vim.env.NIX_CONFIG_HOST
	if from_env and from_env ~= "" then
		return from_env
	end
	local hostname = vim.loop.os_gethostname() or ""
	return hostname ~= "" and hostname or "desktop"
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
local nix_host = detect_nix_host()

-- Global LSP config (applies to all servers)
lsp.config("*", {
	capabilities = capabilities,
	on_attach = function(client, bufnr)
		if client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		if vim.b[bufnr]._lsp_attached then
			return
		end
		vim.b[bufnr]._lsp_attached = true

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
	end,
})

-- Hover with rounded borders
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })

-- Server configs
lsp.config("nixd", {
	cmd = { "nixd" },
	settings = {
		nixd = {
			nixpkgs = { expr = "import <nixpkgs> {}" },
			formatting = { command = { "nixfmt" } },
			options = flake_root
					and {
						nixos = {
							expr = ('(builtins.getFlake "%s").nixosConfigurations.%s.options'):format(
								flake_root,
								nix_host
							),
						},
						["home-manager"] = {
							expr = ('(builtins.getFlake "%s").nixosConfigurations.%s.options.home-manager.users.type.getSubOptions []'):format(
								flake_root,
								nix_host
							),
						},
					}
				or {},
		},
	},
})

lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	settings = {
		Lua = {
			hint = { enable = true, arrayIndex = "Disable" },
			runtime = { version = "LuaJIT" },
			diagnostics = { globals = { "vim" } },
			workspace = { checkThirdParty = false },
			telemetry = { enable = false },
		},
	},
})

-- Simple servers (use default config)
for _, server in ipairs({ "pyright", "vtsls", "kotlin_language_server", "jdtls", "marksman" }) do
	lsp.config(server, {})
end

-- Roslyn (C#)
require("roslyn").setup({
	filewatching = "roslyn",
})

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
for _, server in ipairs({ "nixd", "lua_ls", "pyright", "vtsls", "kotlin_language_server", "jdtls", "marksman" }) do
	lsp.enable(server)
end
