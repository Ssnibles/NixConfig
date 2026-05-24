-- Navigation: motion, search/replace, tmux integration

-- Flash: motion plugin
local flash = require("flash")
flash.setup({})
vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", flash.jump, { desc = "Flash jump" })
vim.keymap.set({ "n", "x", "o" }, "S", flash.treesitter, { desc = "Flash treesitter" })

-- Grug-far: project-wide search/replace
require("grug-far").setup()
vim.keymap.set("n", "<leader>fR", "<cmd>GrugFar<CR>", { desc = "Find and replace" })

-- Smart-splits: resize and move splits intuitively
local smart_splits = require("smart-splits")
local smart_config = {}
if vim.env.TMUX and vim.env.TMUX ~= "" then
	smart_config.multiplexer_integration = "tmux"
end
smart_splits.setup(smart_config)

local map = vim.keymap.set
map("n", "<C-h>", smart_splits.move_cursor_left, { desc = "Move left" })
map("n", "<C-j>", smart_splits.move_cursor_down, { desc = "Move down" })
map("n", "<C-k>", smart_splits.move_cursor_up, { desc = "Move up" })
map("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Move right" })
map("n", "<C-S-h>", smart_splits.resize_left, { desc = "Resize split left" })
map("n", "<C-S-j>", smart_splits.resize_down, { desc = "Resize split down" })
map("n", "<C-S-k>", smart_splits.resize_up, { desc = "Resize split up" })
map("n", "<C-S-l>", smart_splits.resize_right, { desc = "Resize split right" })
