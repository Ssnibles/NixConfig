-- =============================================================================
-- conform.nvim Configuration (Formatting)
-- =============================================================================
local loader = require("lib.loader")

loader.setup("conform", function(conform)
	conform.setup({
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "prettier" },
			typescript = { "prettier" },
			json = { "prettier" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			nix = { "nixfmt" },
			sh = { "shfmt" },
			kotlin = { "ktlint" },
			java = { "google-java-format" },
			cs = { "csharpier" },
		},
		format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
		notify_on_error = true,
	})
	vim.keymap.set({ "n", "v" }, "<leader>cf", function()
		conform.format({ async = true, lsp_format = "fallback" })
	end, { desc = "Format buffer" })
end)
