-- ============================================================================
-- MODERN LSP CONFIGURATION (Using built-in vim.lsp.config)
-- ============================================================================

local lsp = vim.lsp

-- 1. Capabilities & On Attach (Same as before)
local ok_b, blink = pcall(require, "blink.cmp")
local caps = ok_b and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()

local on_attach = function(_, bufnr)
	local opts = { buffer = bufnr, silent = true }
	vim.keymap.set("n", "gd", lsp.buf.definition, { buffer = bufnr, desc = "Go to definition" })
	vim.keymap.set("n", "K", lsp.buf.hover, { buffer = bufnr, desc = "Hover Docs" })
	vim.keymap.set("n", "<leader>a", lsp.buf.code_action, { buffer = bufnr, desc = "Code action" })
	vim.keymap.set("n", "<leader>r", lsp.buf.rename, { buffer = bufnr, desc = "Rename symbol" })
end

-- 2. Configuration Map
-- We define a map of filetype -> server_name to ensure they match correctly.
local ft_to_server = {
	nix = "nixd",
	lua = "lua_ls",
	kotlin = "kotlin_language_server",
	java = "jdtls",
}

-- 3. Server Settings
local server_configs = {
	nixd = {
		cmd = { "nixd" },
		settings = {
			nixd = {
				nixpkgs = { expr = "import <nixpkgs> {}" },
				flake = { flakePath = "/home/josh/NixConfig/flake.nix" },
			},
		},
	},
	lua_ls = {
		cmd = { "lua-language-server" },
		settings = { Lua = { diagnostics = { globals = { "vim" } } } },
	},
	kotlin_language_server = { cmd = { "kotlin-language-server" } },
	jdtls = { cmd = { "jdtls" } },
}

-- 4. Initialization
for name, config in pairs(server_configs) do
	config.capabilities = caps
	config.on_attach = on_attach
	lsp.config[name] = config
end

-- 5. Fixed Autostart Logic
vim.api.nvim_create_autocmd("FileType", {
	pattern = vim.tbl_keys(ft_to_server),
	callback = function(ev)
		local server_name = ft_to_server[ev.match]
		if server_name then
			lsp.enable(server_name) -- This is the preferred way in 0.11 to start/attach
		end
	end,
})
