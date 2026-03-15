-- conform.nvim — format on save + manual format keymap.
-- Formatter binaries are installed via modules/neovim.nix extraPackages.

local conform = require("conform")

conform.setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" }, -- isort first, then black
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

	format_on_save = {
		timeout_ms = 500,
		lsp_format = "fallback", -- replaces deprecated lsp_fallback = true
	},

	-- Notify on format errors rather than silently swallowing them
	notify_on_error = true,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	conform.format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer / range" })
