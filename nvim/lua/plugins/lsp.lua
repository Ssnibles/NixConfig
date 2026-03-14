-- ============================================================================
-- LSP CONFIGURATION
-- Uses Neovim 0.11's built-in vim.lsp.config / vim.lsp.enable API.
-- No lspconfig plugin required for the core setup — nvim-lspconfig is only
-- pulled in for its helper utilities (e.g. :LspInfo).
--
-- Completion capabilities are sourced from plugins/blink.lua, which owns all
-- blink.cmp configuration and exposes a capabilities() helper.
--
-- To add a new language server:
--   1. Add it to ft_to_server (filetype → server name)
--   2. Add its config to server_configs (cmd, settings, etc.)
--   3. Add the server binary to extraPackages in neovim.nix
-- ============================================================================
local lsp = vim.lsp
local caps = require("plugins.blink").capabilities()

-- ============================================================================
-- ON ATTACH
-- Called every time an LSP server attaches to a buffer.
-- Only buffer-local keymaps go here — global LSP config goes in init.lua.
-- ============================================================================
local on_attach = function(_, bufnr)
	local function map(lhs, rhs, desc)
		vim.keymap.set("n", lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	map("gd", lsp.buf.definition, "Go to definition")
	map("K", lsp.buf.hover, "Hover docs")
	map("<leader>a", lsp.buf.code_action, "Code action")
	map("<leader>r", lsp.buf.rename, "Rename symbol")
end

-- ============================================================================
-- FILETYPE → SERVER MAPPING
-- Controls which server is started when a file of that type is opened.
-- ============================================================================
local ft_to_server = {
	nix = "nixd",
	lua = "lua_ls",
	kotlin = "kotlin_language_server",
	java = "jdtls",
}

-- ============================================================================
-- SERVER CONFIGS
-- Per-server settings. cmd must match the binary name on $PATH.
-- ============================================================================
local server_configs = {
	nixd = {
		cmd = { "nixd" },
		settings = {
			nixd = {
				nixpkgs = { expr = "import <nixpkgs> {}" },
				-- Point nixd at your flake so it understands your custom options/modules.
				flake = { flakePath = vim.env.HOME .. "/NixConfig/flake.nix" },
			},
		},
	},
	lua_ls = {
		cmd = { "lua-language-server" },
		settings = {
			Lua = {
				-- Suppress "undefined global `vim`" warnings in neovim config files.
				diagnostics = { globals = { "vim" } },
			},
		},
	},
	kotlin_language_server = { cmd = { "kotlin-language-server" } },
	jdtls = { cmd = { "jdtls" } },
}

-- ============================================================================
-- REGISTER SERVERS
-- Attach shared capabilities and on_attach, then register with vim.lsp.config.
-- ============================================================================
for name, config in pairs(server_configs) do
	config.capabilities = caps
	config.on_attach = on_attach
	lsp.config[name] = config
end

-- ============================================================================
-- AUTOSTART
-- Enable the matching server when a file of a recognised filetype is opened.
-- vim.lsp.enable() is the 0.11+ preferred API (replaces lspconfig's setup()).
-- ============================================================================
vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.tbl_keys(ft_to_server),
	callback = function(ev)
		local server = ft_to_server[ev.match]
		if server then
			lsp.enable(server)
		end
	end,
})

-- ============================================================================
-- FLOAT BORDERS
-- Override the default hover and signature-help handlers so they always use
-- rounded borders, matching the rest of the UI (which-key, diagnostics, etc.).
-- ============================================================================
lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })
lsp.handlers["textDocument/signatureHelp"] = lsp.with(lsp.handlers.signature_help, { border = "rounded" })
