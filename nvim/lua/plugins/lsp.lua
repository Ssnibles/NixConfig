-- =============================================================================
-- LSP Configuration
-- =============================================================================
-- Uses Neovim 0.11+ vim.lsp.config and vim.lsp.enable APIs for native LSP
-- management. Completion capabilities provided by blink.cmp.
local lsp = vim.lsp

-- ── Capabilities ───────────────────────────────────────────────────────────
-- Merge blink.cmp completion capabilities with default LSP capabilities
local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()

-- Enable LSP folding range support
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

-- ── Global LSP Configuration ───────────────────────────────────────────────
-- Apply to all LSP clients with on_attach for buffer-local keymaps
lsp.config("*", {
	on_attach = function(client, bufnr)
		-- Attach nvim-navic for breadcrumb navigation in statusline
		local navic_ok, navic = pcall(require, "nvim-navic")
		if navic_ok and client.server_capabilities.documentSymbolProvider then
			navic.attach(client, bufnr)
		end

		-- Buffer-local keymap helper
		local opts = function(desc)
			return { buffer = bufnr, silent = true, desc = desc }
		end

		-- Navigation keymaps
		vim.keymap.set("n", "gd", lsp.buf.definition, opts("Go to definition"))
		vim.keymap.set("n", "gD", lsp.buf.declaration, opts("Go to declaration"))
		vim.keymap.set("n", "gi", lsp.buf.implementation, opts("Go to implementation"))
		vim.keymap.set("n", "gy", lsp.buf.type_definition, opts("Go to type definition"))
		vim.keymap.set("n", "gr", lsp.buf.references, opts("References"))

		-- Documentation and help
		vim.keymap.set("n", "K", lsp.buf.hover, opts("Hover docs"))
		vim.keymap.set("i", "<C-k>", lsp.buf.signature_help, opts("Signature help"))

		-- Code actions and refactoring
		vim.keymap.set("n", "<leader>a", lsp.buf.code_action, opts("Code action"))
		vim.keymap.set("v", "<leader>a", lsp.buf.code_action, opts("Code action (range)"))
		vim.keymap.set("n", "<leader>r", lsp.buf.rename, opts("Rename symbol"))

		-- Symbol search
		vim.keymap.set("n", "<leader>ls", lsp.buf.document_symbol, opts("Document symbols"))
		vim.keymap.set("n", "<leader>lS", lsp.buf.workspace_symbol, opts("Workspace symbols"))
	end,
	capabilities = capabilities,
})

-- ── Float Window Styling ───────────────────────────────────────────────────
-- Apply rounded borders to LSP hover and signature help windows
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })
lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, { border = "rounded" })

-- ── Server Configurations ──────────────────────────────────────────────────
-- nixd for Nix files with flake support
lsp.config("nixd", {
	cmd = { "nixd" },
	settings = {
		nixd = {
			nixpkgs = { expr = "import <nixpkgs> {}" },
			flake = {
				-- Use environment variable or default to common NixConfig location
				flakePath = vim.env.NIX_CONFIG_FLAKE or vim.env.HOME .. "/NixConfig/flake.nix",
			},
		},
	},
})

-- lua-language-server for Lua files
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

-- Kotlin and Java language servers
lsp.config("kotlin_language_server", { cmd = { "kotlin-language-server" } })
lsp.config("jdtls", { cmd = { "jdtls" } })

-- ── Autostart LSP by Filetype ──────────────────────────────────────────────
-- Enable appropriate LSP server when buffer filetype matches
local ft_servers = {
	nix = "nixd",
	lua = "lua_ls",
	kotlin = "kotlin_language_server",
	java = "jdtls",
}

vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.tbl_keys(ft_servers),
	callback = function(ev)
		lsp.enable(ft_servers[ev.match])
	end,
})
