-- =============================================================================
-- LSP Configuration (Neovim 0.11+)
-- =============================================================================
local loader = require("lib.loader")
local lsp = vim.lsp

local capabilities = (function()
	local ok, blink = pcall(require, "blink.cmp")
	return ok and blink.get_lsp_capabilities() or lsp.protocol.make_client_capabilities()
end)()

lsp.config("*", {
	capabilities = capabilities,
	on_attach = function(client, bufnr)
		local opts = function(desc)
			return { buffer = bufnr, silent = true, desc = desc }
		end
		vim.keymap.set("n", "gd", lsp.buf.definition, opts("Go to definition"))
		vim.keymap.set("n", "gD", lsp.buf.declaration, opts("Go to declaration"))
		vim.keymap.set("n", "gi", lsp.buf.implementation, opts("Go to implementation"))
		vim.keymap.set("n", "gr", lsp.buf.references, opts("References"))
		vim.keymap.set("n", "K", lsp.buf.hover, opts("Hover docs"))
		vim.keymap.set({ "n", "v" }, "<leader>ca", lsp.buf.code_action, opts("Code action"))
		vim.keymap.set("n", "<leader>lR", lsp.buf.rename, opts("Rename symbol"))
		if client.supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end
	end,
})

lsp.handlers["textDocument/hover"] = lsp.with(lsp.handlers.hover, { border = "rounded" })

-- Servers
local servers = { "nixd", "lua_ls", "pyright", "vtsls", "kotlin_language_server", "jdtls", "marksman" }
for _, s in ipairs(servers) do
	lsp.enable(s)
end

loader.setup("roslyn", {
	config = {
		capabilities = capabilities,
		settings = {
			["csharp|inlay_hints"] = {
				csharp_enable_inlay_hints_for_implicit_object_creation = true,
				csharp_enable_inlay_hints_for_implicit_variable_types = true,
			},
		},
	},
})
