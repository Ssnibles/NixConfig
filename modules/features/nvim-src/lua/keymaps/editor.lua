-- General editing and navigation.

local map = vim.keymap.set

-- General
map("n", "U", "<C-r>", { desc = "Redo" })
map("n", "Q", "<Nop>", { desc = "Disable Ex mode" })
map("n", "<C-z>", "<Nop>", { desc = "Disable suspend" })
map({ "i", "v" }, "<C-c>", "<Esc>", { desc = "Normalise Ctrl-c to Escape" })

-- Saving and quitting
map("i", "<C-s>", "<C-o><cmd>update<CR>", { desc = "Save buffer" })
map({ "n", "v" }, "<C-s>", "<cmd>update<CR>", { desc = "Save buffer" })
map("n", "<leader>qq", "<cmd>confirm q<CR>", { desc = "Quit window" })
map("n", "<leader>qw", "<cmd>wq<CR>", { desc = "Save and quit" })
map("n", "<leader>qa", "<cmd>qa<CR>", { desc = "Quit all" })

-- Insert mode
local enter = require("edit.enter")
map("i", "<CR>", enter.cr, { expr = true, desc = "Smart Enter (continue lists and comments)" })
for _, lhs in ipairs({ "<S-CR>", "<M-CR>" }) do
	map("i", lhs, enter.plain_cr, { expr = true, desc = "Newline without continuation" })
end
for _, lhs in ipairs({ "<C-BS>", "<M-BS>", "<C-_>", "<C-/>" }) do
	map("i", lhs, "<C-w>", { desc = "Delete previous word" })
end
map("i", "<C-h>", "<Left>", { desc = "Move caret left" })
map("i", "<C-j>", "<Down>", { desc = "Move caret down" })
map("i", "<C-k>", "<Up>", { desc = "Move caret up" })
map("i", "<C-l>", "<Right>", { desc = "Move caret right" })

-- Line insertion. A count on o/O repeats the typed text on every new line, so
-- create the extra lines first and open one more to land at the far end.
local function counted_open(key)
	return function()
		local count = vim.v.count
		if count < 2 then
			return key
		end
		return "<Cmd>normal! " .. (count - 1) .. key .. "<CR>" .. key
	end
end
map("n", "o", counted_open("o"), { expr = true, desc = "Open lines below (no repeated text)" })
map("n", "O", counted_open("O"), { expr = true, desc = "Open lines above (no repeated text)" })

-- Visual indentation
map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

-- Clipboard and registers
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map({ "n", "v" }, "<leader>D", '"_d', { desc = "Delete to void" })
map("n", "x", '"_x', { desc = "Delete character to void" })
map({ "n", "v" }, "c", '"_c', { desc = "Change to void" })
map({ "n", "v" }, "C", '"_C', { desc = "Change line to void" })
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
map("n", "<leader>P", '"+P', { desc = "Paste before from system clipboard" })

-- Selection and movement
map("n", "<leader>va", "ggVG", { desc = "Select all" })
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Smart line down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Smart line up" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centred)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centred)" })

-- Search
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "n", "nzzzv", { desc = "Next search result (centred)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centred)" })
map("n", "*", "*zz", { desc = "Search word forward (centred)" })
map("n", "#", "#zz", { desc = "Search word backward (centred)" })

-- Miscellaneous
map("n", "<leader>cd", "<cmd>cd %:p:h<CR>", { desc = "Change to file directory" })
map("n", "<C-.>", "@@", { desc = "Repeat last macro" })
