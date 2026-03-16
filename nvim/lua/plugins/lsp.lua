-- =============================================================================
-- LSP Configuration (Neovim 0.11+ APIs)
-- =============================================================================
local lsp = vim.lsp

-- Capabilities with blink.cmp
local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	if ok then
		return blink.get_lsp_capabilities()
	end
	return lsp.protocol.make_client_capabilities()
end)()

capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

-- Global LSP config
lsp.config("*", {
	on_attach = function(client, bufnr)
		-- nvim-navic for breadcrumbs
		local navic_ok, navic = pcall(require, "nvim-navic")
		if navic_ok and client.server_capabilities.documentSymbolProvider then
			navic.attach(client, bufnr)
		end

		local opts = function(desc)
			return { buffer = bufnr, silent = true, desc = desc }
		end

		-- Navigation
		vim.keymap.set("n", "gd", lsp.buf.definition, opts("Go to definition"))
		vim.keymap.set("n", "gD", lsp.buf.declaration, opts("Go to declaration"))
		vim.keymap.set("n", "gi", lsp.buf.implementation, opts("Go to implementation"))
		vim.keymap.set("n", "gy", lsp.buf.type_definition, opts("Go to type definition"))
		vim.keymap.set("n", "gr", lsp.buf.references, opts("References"))

		-- Docs
		vim.keymap.set("n", "K", lsp.buf.hover, opts("Hover docs"))
		vim.keymap.set("i", "<C-k>", lsp.buf.signature_help, opts("Signature help"))

		-- Actions
		vim.keymap.set("n", "<leader>a", lsp.buf.code_action, opts("Code action"))
		vim.keymap.set("v", "<leader>a", lsp.buf.code_action, opts("Code action"))
		vim.keymap.set("n", "<leader>r", lsp.buf.rename, opts("Rename"))

		-- Symbols
		vim.keymap.set("n", "<leader>ls", lsp.buf.document_symbol, opts("Document symbols"))
		vim.keymap.set("n", "<leader>lS", lsp.buf.workspace_symbol, opts("Workspace symbols"))
	end,
	capabilities = capabilities,
})

-- Float styling
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })
lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, { border = "rounded" })

-- Server configs
lsp.config("nixd", {
	cmd = { "nixd" },
	settings = {
		nixd = {
			nixpkgs = { expr = "import <nixpkgs> {}" },
			flake = {
				flakePath = vim.env.NIX_CONFIG_FLAKE or vim.env.HOME .. "/NixConfig/flake.nix",
			},
		},
	},
})

lsp.config("lua_ls", {
	cmd = { "lua-language-server" },
	settings = {
		Lua = {
			runtime = { version = "LuaJIT" },
			workspace = { checkThirdParty = false },
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})

lsp.config("kotlin_language_server", { cmd = { "kotlin-language-server" } })
lsp.config("jdtls", { cmd = { "jdtls" } })

-- Auto-start by filetype
local ft_servers = {
	nix = "nixd",
	lua = "lua_ls",
	kotlin = "kotlin_language_server",
	java = "jdtls",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.tbl_keys(ft_servers),
	callback = function(ev)
		local server = ft_servers[ev.match]
		if server then
			lsp.enable(server)
		end
	end,
})
