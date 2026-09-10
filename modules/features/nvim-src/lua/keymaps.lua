local map = vim.keymap.set

-- ── General ──────────────────────────────────────────────────────────
map("n", "U", "<C-r>", { desc = "Redo" })
map("n", "Q", "<Nop>", { desc = "Disable Ex mode" })
map("n", "<C-z>", "<Nop>", { desc = "Disable suspend" })
map({ "i", "v" }, "<C-c>", "<Esc>", { desc = "Normalize Ctrl-c to Escape" })

-- ── Saving & Quitting ────────────────────────────────────────────────
map("i", "<C-s>", "<C-o><cmd>update<CR>", { desc = "Save buffer" })
map({ "n", "v" }, "<C-s>", "<cmd>update<CR>", { desc = "Save buffer" })
map("n", "<leader>qq", "<cmd>confirm q<CR>", { desc = "Quit window" })
map("n", "<leader>qw", "<cmd>wq<CR>", { desc = "Save and quit" })
map("n", "<leader>qa", "<cmd>qa<CR>", { desc = "Quit all" })

-- ── Insert Mode ──────────────────────────────────────────────────────
map("i", "<C-BS>", "<C-w>", { desc = "Delete previous word" })
map("i", "<M-BS>", "<C-w>", { desc = "Delete previous word" })
map("i", "\x1f", "<C-w>", { desc = "Delete previous word (Ctrl+BS)" })
map("i", "<C-_>", "<C-w>", { desc = "Delete previous word (Ctrl+BS)" })
map("i", "<C-/>", "<C-w>", { desc = "Delete previous word (Ctrl+BS)" })
map("i", "<C-h>", "<Left>", { desc = "Move caret left" })
map("i", "<C-j>", "<Down>", { desc = "Move caret down" })
map("i", "<C-k>", "<Up>", { desc = "Move caret up" })
map("i", "<C-l>", "<Right>", { desc = "Move caret right" })

-- ── Visual Indentation ───────────────────────────────────────────────
map("v", "<", "<gv", { desc = "Indent left (keep selection)" })
map("v", ">", ">gv", { desc = "Indent right (keep selection)" })

-- ── Clipboard & Registers ────────────────────────────────────────────
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map({ "n", "v" }, "<leader>D", '"_d', { desc = "Delete to void" })
map("n", "x", '"_x', { desc = "Delete character to void" })
map({ "n", "v" }, "c", '"_c', { desc = "Change to void" })
map({ "n", "v" }, "C", '"_C', { desc = "Change line to void" })
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>Y", '"+Y', { desc = "Yank line to system clipboard" })
map("n", "<leader>P", '"+P', { desc = "Paste before from system clipboard" })

-- ── Selection & Movement ─────────────────────────────────────────────
map("n", "<leader>va", "ggVG", { desc = "Select all" })
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "Smart line down" })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "Smart line up" })

-- ── Search ───────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "n", "nzzzv", { desc = "Next search result (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centered)" })
map("n", "*", "*zz", { desc = "Search word forward (centered)" })
map("n", "#", "#zz", { desc = "Search word backward (centered)" })
map("x", "*", [["zy/\V<C-r>=escape(@z, '/\')<CR><CR>]], { desc = "Search visual selection forward", silent = true })
map("x", "#", [["zy?\V<C-r>=escape(@z, '?\')<CR><CR>]], { desc = "Search visual selection backward", silent = true })

-- ── Windows ──────────────────────────────────────────────────────────
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wq", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Only window" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalize windows" })
map("n", "<leader>wh", "<C-w>H", { desc = "Move window left" })
map("n", "<leader>wl", "<C-w>L", { desc = "Move window right" })
map("n", "<leader>wj", "<C-w>J", { desc = "Move window down" })
map("n", "<leader>wk", "<C-w>K", { desc = "Move window up" })

-- ── Buffers & Tabs ───────────────────────────────────────────────────
map("n", "<leader>bd", function()
	local ok, bufremove = pcall(require, "mini.bufremove")
	if ok then
		bufremove.delete(0, false)
	else
		vim.cmd("bdelete")
	end
end, { desc = "Delete buffer" })

map("n", "<leader>bo", function()
	local current = vim.api.nvim_get_current_buf()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if buf ~= current and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
			vim.api.nvim_buf_delete(buf, { unload = false })
		end
	end
end, { desc = "Close other buffers" })

map("n", "<leader>`", "<cmd>b#<CR>", { desc = "Alternate buffer" })
map("n", "<C-Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<C-S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "]t", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "[t", "<cmd>tabprevious<CR>", { desc = "Previous tab" })
map("n", "<leader>Tn", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>Tc", "<cmd>tabclose<CR>", { desc = "Close tab" })

-- ── Quickfix & Location List ─────────────────────────────────────────
map("n", "]q", "<cmd>cnext<CR>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprevious<CR>", { desc = "Previous quickfix" })
map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "<leader>qf", function()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.bo[vim.api.nvim_win_get_buf(win)].buftype == "quickfix" then
			vim.cmd("cclose")
			return
		end
	end
	vim.cmd("copen")
end, { desc = "Toggle quickfix list" })
map("n", "<leader>ql", "<cmd>lopen<CR>", { desc = "Open location list" })
map("n", "<leader>qL", "<cmd>lclose<CR>", { desc = "Close location list" })
map("n", "]l", "<cmd>lnext<CR>", { desc = "Next location" })
map("n", "[l", "<cmd>lprevious<CR>", { desc = "Previous location" })

-- ── Diagnostics ──────────────────────────────────────────────────────
vim.diagnostic.config({
	virtual_text = {
		spacing = 4,
		prefix = "●",
		severity = { min = vim.diagnostic.severity.WARN },
		format = function(d)
			local msg = d.message
			return msg and msg:gsub("%s+", " "):gsub("\n", " ") or ""
		end,
	},
	underline = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "×",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.HINT] = "•",
			[vim.diagnostic.severity.INFO] = "•",
		},
	},
	severity_sort = true,
	float = { border = "rounded", source = "if_many", max_width = 70 },
	update_in_insert = false,
})

map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })
map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next error" })
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Previous error" })

-- ── Toggles ──────────────────────────────────────────────────────────
map("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle wrap" })
map("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell" })
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", { desc = "Toggle relative numbers" })
map("n", "<leader>td", function()
	vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
map("n", "<leader>ti", function()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
end, { desc = "Toggle inlay hints" })
map("n", "<leader>tc", function()
	vim.g.minicursorword_disable = not vim.g.minicursorword_disable
	vim.notify("Cursor word highlighting " .. (vim.g.minicursorword_disable and "disabled" or "enabled"))
end, { desc = "Toggle cursor word" })

-- ── LSP (non-attach) ────────────────────────────────────────────────
map("n", "<leader>li", "<cmd>LspInfo<CR>", { desc = "LSP info" })
map("n", "<leader>lr", "<cmd>LspRestart<CR>", { desc = "Restart LSP" })
map("n", "<leader>lf", "<cmd>FzfLua lsp_finder<CR>", { desc = "LSP finder" })
map("n", "<leader>lh", "<cmd>LspHealth<CR>", { desc = "LSP health" })
map("n", "<leader>lR", "<cmd>SmartRename<CR>", { desc = "Smart rename/replace" })

-- ── Pickers (FzfLua) ────────────────────────────────────────────────
map("n", "<C-p>", "<cmd>FzfLua files<CR>", { desc = "File picker" })
map("n", "<leader>/", "<cmd>FzfLua live_grep<CR>", { desc = "Search project" })
map("n", "<leader>ff", "<cmd>FzfLua files<CR>", { desc = "Find files" })
map("n", "<leader>fo", "<cmd>FzfLua oldfiles<CR>", { desc = "Recent files" })
map("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", { desc = "Buffers" })
map("n", "<leader>fg", "<cmd>FzfLua live_grep<CR>", { desc = "Live grep" })
map("n", "<leader>fw", "<cmd>FzfLua grep_cword<CR>", { desc = "Grep word" })
map("n", "<leader>fW", "<cmd>FzfLua grep_cWORD<CR>", { desc = "Grep WORD" })
map("n", "<leader>f/", "<cmd>FzfLua blines<CR>", { desc = "Search buffer" })
map("n", "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", { desc = "Document symbols" })
map("n", "<leader>fS", "<cmd>FzfLua lsp_workspace_symbols<CR>", { desc = "Workspace symbols" })
map("n", "<leader>fd", "<cmd>FzfLua diagnostics_document<CR>", { desc = "Diagnostics" })
map("n", "<leader>fh", "<cmd>FzfLua help_tags<CR>", { desc = "Help" })
map("n", "<leader>fk", "<cmd>FzfLua keymaps<CR>", { desc = "Keymaps" })
map("n", "<leader>f.", "<cmd>FzfLua resume<CR>", { desc = "Resume last picker" })
map("n", "<leader>fR", "<cmd>GrugFar<CR>", { desc = "Find and replace (project)" })

-- ── Git Pickers ──────────────────────────────────────────────────────
map("n", "<leader>gc", "<cmd>FzfLua git_commits<CR>", { desc = "Git commits" })
map("n", "<leader>gS", "<cmd>FzfLua git_status<CR>", { desc = "Git status (picker)" })
map("n", "<leader>gl", "<cmd>FzfLua git_commits<CR>", { desc = "Git log" })
map("n", "<leader>gL", "<cmd>FzfLua git_bcommits<CR>", { desc = "Git log (current file)" })
map("n", "<leader>gB", "<cmd>FzfLua git_branches<CR>", { desc = "Git branches" })
map("n", "<leader>gF", "<cmd>FzfLua git_stash<CR>", { desc = "Git stash" })

-- ── Miscellaneous ────────────────────────────────────────────────────
map("n", "<leader>cd", "<cmd>cd %:p:h<CR>", { desc = "Change to file directory" })
map("n", "zz", "za", { desc = "Toggle Folds" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
