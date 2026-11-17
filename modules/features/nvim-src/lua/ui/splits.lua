-- Window movement and resizing, including terminal and multiplexer panes.

local splits = require("smart-splits")

splits.setup({})

vim.keymap.set("n", "<C-h>", splits.move_cursor_left, { desc = "Move left" })
vim.keymap.set("n", "<C-j>", splits.move_cursor_down, { desc = "Move down" })
vim.keymap.set("n", "<C-k>", splits.move_cursor_up, { desc = "Move up" })
vim.keymap.set("n", "<C-l>", splits.move_cursor_right, { desc = "Move right" })
vim.keymap.set("n", "<C-S-h>", splits.resize_left, { desc = "Resize left" })
vim.keymap.set("n", "<C-S-j>", splits.resize_down, { desc = "Resize down" })
vim.keymap.set("n", "<C-S-k>", splits.resize_up, { desc = "Resize up" })
vim.keymap.set("n", "<C-S-l>", splits.resize_right, { desc = "Resize right" })
