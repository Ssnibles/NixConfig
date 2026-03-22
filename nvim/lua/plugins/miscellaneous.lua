local loader = require("lib.loader")

loader.setup("vim-tmux-navigator", function(tmux_nav)
	-- No setup required, just load the plugin
end)

loader.setup("leap", function(leap)
	leap.opts.safe_labels = {} -- Disable 'safe' labels to ensure you always get a consistent experience

	vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", function()
		local current_window = vim.api.nvim_get_current_win()
		leap.leap({
			target_windows = vim.api.nvim_tabpage_list_wins(0),
		})
	end, { desc = "Leap search" })
end)
