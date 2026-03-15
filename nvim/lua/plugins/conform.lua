-- =============================================================================
-- conform.nvim Configuration
-- =============================================================================
-- Format on save with formatter fallback to LSP. Formatter binaries are
-- installed via Nix modules/neovim.nix extraPackages.
local conform = require("conform")

conform.setup({
	-- Formatters organized by filetype
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		jsx = { "prettier" },
		tsx = { "prettier" },
		json = { "prettier" },
		jsonc = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
		scss = { "prettier" },
		nix = { "nixfmt" },
		sh = { "shfmt" },
		bash = { "shfmt" },
		kotlin = { "ktlint" },
		java = { "google-java-format" },
	},
	-- Format on save with 500ms timeout and LSP fallback
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	-- Show notification on format errors
	notify_on_error = true,
})

-- Manual format keymap for normal and visual mode
vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer / range" })
