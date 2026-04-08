-- Navigation: motion, search/replace, tmux integration

-- Leap: fast motion
local leap = require("leap")
leap.opts.safe_labels = {}
vim.keymap.set({ "n", "x", "o" }, "S", function()
	leap.leap({ target_windows = vim.api.nvim_tabpage_list_wins(0) })
end, { desc = "Leap (cross-window)" })

-- Grug-far: project-wide search/replace
require("grug-far").setup()
vim.keymap.set("n", "<leader>sr", "<cmd>GrugFar<CR>", { desc = "Search and replace" })

-- Tmux navigator
pcall(require, "vim-tmux-navigator")
