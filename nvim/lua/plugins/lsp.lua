-- =============================================================================
-- LSP Configuration
-- =============================================================================
-- Language Server Protocol setup using Neovim's native LSP client (0.11+).
-- Configured for nixd, lua_ls, kotlin_language_server, and jdtls.
-- =============================================================================

local lsp = vim.lsp

-- ── Capabilities (with blink.cmp integration) ─────────────────────────────
local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	if ok then
		return blink.get_lsp_capabilities()
	end
	return lsp.protocol.make_client_capabilities()
end)()

-- Advertise folding range support so servers can send fold info
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}

-- ── Global LSP Config ──────────────────────────────────────────────────────
lsp.config("*", {
	on_attach = function(client, bufnr)
		local opts = function(desc)
			return { buffer = bufnr, silent = true, desc = desc }
		end

		-- ── Navigation ───────────────────────────────────────────────────
		vim.keymap.set("n", "gd", lsp.buf.definition, opts("Go to definition"))
		vim.keymap.set("n", "gD", lsp.buf.declaration, opts("Go to declaration"))
		vim.keymap.set("n", "gi", lsp.buf.implementation, opts("Go to implementation"))
		vim.keymap.set("n", "gy", lsp.buf.type_definition, opts("Go to type definition"))
		vim.keymap.set("n", "gr", lsp.buf.references, opts("References"))

		-- ── Docs ─────────────────────────────────────────────────────────
		vim.keymap.set("n", "K", lsp.buf.hover, opts("Hover docs"))
		vim.keymap.set("i", "<C-k>", lsp.buf.signature_help, opts("Signature help"))

		-- ── Actions ──────────────────────────────────────────────────────
		vim.keymap.set("n", "<leader>a", lsp.buf.code_action, opts("Code action"))
		vim.keymap.set("v", "<leader>a", lsp.buf.code_action, opts("Code action (range)"))
		-- Rename moved to <leader>lR: keeps all LSP actions under <leader>l*
		-- and avoids shadowing any future global <leader>r binding
		vim.keymap.set("n", "<leader>lR", lsp.buf.rename, opts("Rename symbol"))

		-- ── Symbols ──────────────────────────────────────────────────────
		vim.keymap.set("n", "<leader>ls", lsp.buf.document_symbol, opts("Document symbols"))
		vim.keymap.set("n", "<leader>lS", lsp.buf.workspace_symbol, opts("Workspace symbols"))
	end,
	capabilities = capabilities,
})

-- ── Float Styling ──────────────────────────────────────────────────────────
lsp.handlers["textDocument/hover"] =
	lsp.with(lsp.handlers.hover, { border = "rounded", max_width = 80, max_height = 20 })
lsp.handlers["textDocument/signatureHelp"] =
	lsp.with(lsp.handlers.signature_help, { border = "rounded", max_width = 80 })

-- ── Server Configs ─────────────────────────────────────────────────────────
lsp.config("nixd", {
	cmd = { "nixd" },
	settings = {
		nixd = {
			nixpkgs = { expr = "import <nixpkgs> {}" },
			flake = {
				-- Prefer the env var so the path works across both machines;
				-- fall back to the conventional NixConfig location
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

-- ── Auto-start by Filetype ────────────────────────────────────────────────
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
