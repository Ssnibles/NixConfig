-- =============================================================================
-- Neogit Configuration
-- =============================================================================
local loader = require("lib.loader")

loader.setup("neogit", function(neogit)
	neogit.setup({
		disable_insert_on_commit = "auto",
		filewatcher = { enabled = true },
		integrations = { fzf_lua = true },
		popup = { kind = "floating" },
		graph_style = "unicode",
	})
	vim.keymap.set("n", "<leader>gn", neogit.open, { desc = "Neogit status" })
end)
