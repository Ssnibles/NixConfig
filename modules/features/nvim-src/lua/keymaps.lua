local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlights" })
map("n", "U", "<C-r>", { desc = "Redo" })
map("n", "Q", "<Nop>", { desc = "Disable Ex mode" })
map("n", "<C-z>", "<Nop>", { desc = "Disable suspend" })
map("n", "<C-w>q", "<Nop>", { desc = "Disable window close" })

map("i", "<C-s>", "<C-o><cmd>update<CR>", { desc = "Save buffer" })
map({ "n", "v" }, "<C-s>", "<cmd>update<CR>", { desc = "Save buffer" })
map("n", "<leader>qq", "<cmd>confirm q<CR>", { desc = "Quit window" })
map("n", "<leader>qw", "<cmd>wq<CR>", { desc = "Save and quit" })
map("n", "<leader>qa", "<cmd>qa<CR>", { desc = "Quit all" })

map("i", "<C-BS>", "<C-w>", { desc = "Delete previous word" })
map("i", "<M-BS>", "<C-w>", { desc = "Delete previous word" })
map("i", "<C-h>", "<Left>", { desc = "Move caret left" })
map("i", "<C-l>", "<Right>", { desc = "Move caret right" })

map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

local function open_lines(key)
	return function()
		local count = vim.v.count1
		if count == 1 then
			vim.api.nvim_feedkeys(key, "n", false)
			return
		end
		local keys = key .. string.rep("<CR>", count - 1) .. "<Esc>" .. (count - 1) .. "kA"
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
	end
end

map("n", "o", open_lines("o"), { desc = "Open line(s) below" })
map("n", "O", open_lines("O"), { desc = "Open line(s) above" })

map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map({ "n", "v" }, "<leader>D", '"_d', { desc = "Delete to void" })
map("n", "x", '"_x', { desc = "Delete character to void" })

map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
map({ "n", "v" }, "<leader>P", '"+p', { desc = "Paste from system clipboard" })

map("n", "<leader>va", "ggVG", { desc = "Select all" })

map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Smart line down" })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Smart line up" })

map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })
map("n", "*", "*zz", { desc = "Search word forward (centered)" })
map("n", "#", "#zz", { desc = "Search word backward (centered)" })

map("x", "*", [["zy/\V<C-r>=escape(@z, '/\')<CR><CR>]], { desc = "Search visual selection forward", silent = true })
map("x", "#", [["zy?\V<C-r>=escape(@z, '?\')<CR><CR>]], { desc = "Search visual selection backward", silent = true })

map("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wc", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Only window" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize windows" })
map("n", "<leader>wh", "<C-w>H", { desc = "Move window left" })
map("n", "<leader>wl", "<C-w>L", { desc = "Move window right" })
map("n", "<leader>wj", "<C-w>J", { desc = "Move window down" })
map("n", "<leader>wk", "<C-w>K", { desc = "Move window up" })

map("n", "<leader>bo", "<cmd>%bd|e#|bd#<CR>", { desc = "Close other buffers" })
map("n", "<leader>`", "<cmd>b#<CR>", { desc = "Alternate buffer" })
map("n", "<C-Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<C-S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })

map("n", "]t", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[t", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>Tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>Tc", "<cmd>tabclose<CR>", { desc = "Close tab" })

map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous quickfix" })
map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "<leader>ql", "<cmd>lopen<CR>", { desc = "Open location list" })
map("n", "<leader>qL", "<cmd>lclose<CR>", { desc = "Close location list" })

map("n", "]l", "<cmd>lnext<CR>", { desc = "Next location" })
map("n", "[l", "<cmd>lprevious<CR>", { desc = "Previous location" })

map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })

map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next error" })
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Previous error" })

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

map("n", "<leader>li", "<cmd>LspInfo<CR>", { desc = "LSP info" })
map("n", "<leader>lr", "<cmd>LspRestart<CR>", { desc = "Restart LSP" })
map("n", "<leader>lf", "<cmd>FzfLua lsp_finder<CR>", { desc = "LSP finder" })
map("n", "<leader>lh", "<cmd>LspHealth<CR>", { desc = "LSP health" })
map("n", "<leader>lR", "<cmd>SmartRename<CR>", { desc = "Smart rename/replace" })

map("n", "<C-p>", "<cmd>FzfLua files<CR>", { desc = "File picker" })
map("n", "<leader>/", "<cmd>FzfLua live_grep<CR>", { desc = "Search project" })

map("n", "<leader>cd", "<cmd>cd %:p:h<CR>", { desc = "Change to file directory" })
