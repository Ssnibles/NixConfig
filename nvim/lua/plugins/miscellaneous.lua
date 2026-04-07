-- =============================================================================
-- Miscellaneous Utilities
-- =============================================================================
local loader = require("lib.loader")

loader.setup("leap", function(leap)
	leap.opts.safe_labels = {}
	vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", function()
		leap.leap({ target_windows = vim.api.nvim_tabpage_list_wins(0) })
	end, { desc = "Leap search" })
end)

loader.setup("grug-far", { default_method = "rg" })

loader.require("vim-tmux-navigator")
