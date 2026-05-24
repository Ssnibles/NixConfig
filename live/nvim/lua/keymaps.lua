-- Core keymaps (plugin keymaps are defined in their respective config files)
local map = vim.keymap.set

-- General
map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("i", "jk", "<Esc>")
map("i", "<C-BS>", "<C-w>", { desc = "Delete previous word" })
map("i", "<C-s>", "<C-o><cmd>update<CR>", { desc = "Save buffer" })
map("n", "U", "<C-r>", { desc = "Redo" })
map({ "n", "v" }, "<C-s>", "<cmd>update<CR>", { desc = "Save buffer" })
map("n", "<leader>q", "<cmd>confirm q<CR>", { desc = "Quit window" })
map("n", "<leader>qw", "<cmd>wq<CR>", { desc = "Save and quit" })
map("n", "<leader>qq", "<cmd>qa<CR>", { desc = "Quit all" })

-- Better movement
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
map("i", "<C-h>", "<Left>", { desc = "Move caret left" })
map("i", "<C-j>", "<Down>", { desc = "Move caret down" })
map("i", "<C-k>", "<Up>", { desc = "Move caret up" })
map("i", "<C-l>", "<Right>", { desc = "Move caret right" })
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")

-- Search selected text in visual mode
map("x", "*", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("y/\\V<C-r>=escape(@\", '/\\')<CR><CR>", true, false, true), "n", false)
end, { desc = "Search visual selection forward" })
map("x", "#", function()
	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("y?\\V<C-r>=escape(@\", '?\\')<CR><CR>", true, false, true), "n", false)
end, { desc = "Search visual selection backward" })

-- Visual mode
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Clipboard
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map({ "n", "v" }, "<leader>D", '"_d', { desc = "Delete to void" })

-- Windows
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wc", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Only window" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize windows" })

-- Buffers
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<CR>", { desc = "Close other buffers" })

-- Quickfix
map("n", "]q", "<cmd>cnext<CR>")
map("n", "[q", "<cmd>cprevious<CR>")
map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "<leader>qa", "<cmd>cclose<CR><cmd>lclose<CR>", { desc = "Close all lists" })
map("n", "]l", "<cmd>lnext<CR>", { desc = "Next location" })
map("n", "[l", "<cmd>lprevious<CR>", { desc = "Previous location" })
map("n", "<leader>ql", "<cmd>lopen<CR>", { desc = "Open location list" })
map("n", "<leader>qL", "<cmd>lclose<CR>", { desc = "Close location list" })

-- Diagnostics
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next error" })
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Prev error" })

-- LSP (buffer-independent)
map("n", "<leader>li", "<cmd>LspInfo<CR>", { desc = "LSP info" })
map("n", "<leader>lr", "<cmd>LspRestart<CR>", { desc = "Restart LSP" })
map("n", "<leader>lf", "<cmd>FzfLua lsp_finder<CR>", { desc = "LSP finder" })
map("n", "<leader>lh", "<cmd>LspHealth<CR>", { desc = "LSP health" })
map("n", "<leader>cr", "<cmd>SmartRename<CR>", { desc = "Context rename/replace" })

-- Toggles
map("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle wrap" })
map("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell" })
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
map("n", "<leader>td", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
map("n", "<leader>ti", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
	vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
end, { desc = "Toggle inlay hints" })
map("n", "<leader>tc", function()
	if vim.g.user_cursorword_enabled == nil then
		vim.g.user_cursorword_enabled = true
	end
	vim.g.user_cursorword_enabled = not vim.g.user_cursorword_enabled
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		vim.b[buf].minicursorword_disable = not vim.g.user_cursorword_enabled
	end
end, { desc = "Toggle cursor word" })

-- Tab navigation
map("n", "]t", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[t", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>Tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>Tc", "<cmd>tabclose<CR>", { desc = "Close tab" })

-- Unbind
map("n", "<C-Z>", "<Nop>")
