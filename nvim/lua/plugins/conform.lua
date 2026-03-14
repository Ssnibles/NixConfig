-- ============================================================================
-- CONFORM (AUTO-FORMATTER)
-- Runs formatters on save and provides a manual format keymap.
-- Formatters are installed via neovim.nix extraPackages, not here.
-- ============================================================================
local conform = require("conform")

conform.setup({
	-- Map filetypes to their formatters. Multiple formatters run in order.
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" }, -- isort first so black doesn't reorder imports
		javascript = { "prettier" },
		typescript = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		-- nixfmt is the RFC-style formatter adopted by nixpkgs upstream.
		-- The conform formatter name is "nixfmt" (binary: nixfmt).
		nix = { "nixfmt" },
	},

	-- Automatically format on save. lsp_fallback tries the LSP formatter if no
	-- conform formatter matches (e.g. for filetypes not listed above).
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
})

-- Manual format: useful when you want to format without saving,
-- or when format-on-save is intentionally disabled for a buffer.
vim.keymap.set("n", "<leader>f", function()
	conform.format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
