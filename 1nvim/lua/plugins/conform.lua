-- =============================================================================
-- conform.nvim
-- =============================================================================
if not pcall(require, "conform") then
	return
end

local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		html = { "prettier" },
		css = { "prettier" },
		nix = { "nixfmt" },
		sh = { "shfmt" },
		kotlin = { "ktlint" },
		java = { "google-java-format" },
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback",
	},
	notify_on_error = true,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })
