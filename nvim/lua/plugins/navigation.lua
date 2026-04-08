-- Navigation: motion, search/replace, tmux integration

-- Leap: fast motion
require("leap")
vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)", { desc = "Leap" })
vim.keymap.set("n", "S", "<Plug>(leap-from-window)", { desc = "Leap from window" })
vim.keymap.set({ "x", "o" }, "x", "<Plug>(leap-forward-till)", { desc = "Leap forward till" })
vim.keymap.set({ "x", "o" }, "X", "<Plug>(leap-backward-till)", { desc = "Leap backward till" })
require("leap.user").set_repeat_keys("<enter>", "<backspace>", { relative_directions = true })

-- Grug-far: project-wide search/replace
require("grug-far").setup()
vim.keymap.set("n", "<leader>sr", "<cmd>GrugFar<CR>", { desc = "Search and replace" })

-- Smart-splits: resize and move splits intuitively
local smart_splits = require("smart-splits")
smart_splits.setup({})
vim.keymap.set("n", "<C-S-h>", smart_splits.resize_left, { desc = "Resize split left" })
vim.keymap.set("n", "<C-S-j>", smart_splits.resize_down, { desc = "Resize split down" })
vim.keymap.set("n", "<C-S-k>", smart_splits.resize_up, { desc = "Resize split up" })
vim.keymap.set("n", "<C-S-l>", smart_splits.resize_right, { desc = "Resize split right" })

-- Tmux navigator
pcall(require, "vim-tmux-navigator")
