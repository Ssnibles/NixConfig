local loader = require("lib.loader")

loader.setup("vim-tmux-navigator", function(tmux_nav)
	-- No setup required, just load the plugin
end)

loader.setup("leap", function(leap)
	leap.opts.safe_labels = {}
	vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", function()
		leap.leap({ target_windows = vim.api.nvim_tabpage_list_wins(0) })
	end, { desc = "Leap search" })
end)

loader.setup("grug-far", function(grug_far)
	grug_far.setup({
		-- Optional: Set the default search method (default is "rg")
		default_method = "rg",
	})
end)
