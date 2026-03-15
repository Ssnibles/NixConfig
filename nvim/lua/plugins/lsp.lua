-- LSP configuration using Neovim 0.11's built-in vim.lsp.config / vim.lsp.enable API.
-- Completion capabilities come from blink.cmp (plugins/completion.lua).

local lsp = vim.lsp

-- ── Capabilities (blink.cmp or built-in fallback) ─────────────────────────
local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()

-- Enable folding via LSP if the server supports it
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

-- ── On-attach keymaps ─────────────────────────────────────────────────────
lsp.config("*", {
	on_attach = function(client, bufnr)
		-- nvim-navic: breadcrumb location in statusline
		local navic_ok, navic = pcall(require, "nvim-navic")
		if navic_ok and client.server_capabilities.documentSymbolProvider then
			navic.attach(client, bufnr)
		end

		local opts = function(desc)
			return { buffer = bufnr, silent = true, desc = desc }
		end

		vim.keymap.set("n", "gd", lsp.buf.definition, opts("Go to definition"))
		vim.keymap.set("n", "gD", lsp.buf.declaration, opts("Go to declaration"))
		vim.keymap.set("n", "gi", lsp.buf.implementation, opts("Go to implementation"))
		vim.keymap.set("n", "gy", lsp.buf.type_definition, opts("Go to type definition"))
		vim.keymap.set("n", "gr", lsp.buf.references, opts("References"))
		vim.keymap.set("n", "K", lsp.buf.hover, opts("Hover docs"))
		-- <C-k> in normal mode is reserved for smart-splits window navigation (keymaps.lua).
		-- Signature help is available in insert mode and via the LSP info float.
		vim.keymap.set("i", "<C-k>", lsp.buf.signature_help, opts("Signature help"))
		vim.keymap.set("n", "<leader>a", lsp.buf.code_action, opts("Code action"))
		vim.keymap.set("v", "<leader>a", lsp.buf.code_action, opts("Code action (range)"))
		vim.keymap.set("n", "<leader>r", lsp.buf.rename, opts("Rename symbol"))
		vim.keymap.set("n", "<leader>ls", lsp.buf.document_symbol, opts("Document symbols"))
		vim.keymap.set("n", "<leader>lS", lsp.buf.workspace_symbol, opts("Workspace symbols"))
	end,
	capabilities = capabilities,
})

-- ── Float styling ─────────────────────────────────────────────────────────
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })
lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, { border = "rounded" })

-- ── Server configurations ─────────────────────────────────────────────────
lsp.config("nixd", {
	cmd = { "nixd" },
	settings = {
		nixd = {
			nixpkgs = { expr = "import <nixpkgs> {}" },
			flake = { flakePath = vim.env.HOME .. "/NixConfig/flake.nix" },
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

-- ── Autostart by filetype ─────────────────────────────────────────────────
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
