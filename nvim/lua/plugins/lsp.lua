-- LSP configuration using Neovim 0.11's built-in vim.lsp.config / vim.lsp.enable API.
-- Completion capabilities come from blink.cmp via plugins/completion.lua.

local lsp = vim.lsp

-- ── On-attach keymaps ─────────────────────────────────────────────────────
lsp.config("*", {
	on_attach = function(_, bufnr)
		local opts = { buffer = bufnr, silent = true }
		vim.keymap.set("n", "gd", lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
		vim.keymap.set("n", "K", lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover docs" }))
		vim.keymap.set("n", "<leader>a", lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
		vim.keymap.set("n", "<leader>r", lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
		vim.keymap.set("n", "gr", lsp.buf.references, vim.tbl_extend("force", opts, { desc = "References" }))
	end,
	capabilities = (function()
		local ok, blink = pcall(require, "blink.cmp")
		return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
	end)(),
})

-- ── Rounded borders on hover / signature help ─────────────────────────────
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
	settings = { Lua = { diagnostics = { globals = { "vim" } } } },
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
