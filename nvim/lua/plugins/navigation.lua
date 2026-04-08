-- Navigation: motion, search/replace, tmux integration

-- Leap: fast motion
local leap = require("leap")
leap.opts.safe_labels = {}

local leap_cross_window = function()
	leap.leap({ target_windows = vim.api.nvim_tabpage_list_wins(0) })
end

vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", leap_cross_window, { desc = "Jump (cross-window)" })
vim.keymap.set({ "n", "x", "o" }, "S", leap_cross_window, { desc = "Jump (cross-window)" })

-- Grug-far: project-wide search/replace
require("grug-far").setup()
vim.keymap.set("n", "<leader>sr", "<cmd>GrugFar<CR>", { desc = "Search and replace" })

-- Tmux navigator
pcall(require, "vim-tmux-navigator")
