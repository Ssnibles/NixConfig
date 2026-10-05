local map = vim.keymap.set

-- ── General ──────────────────────────────────────────────────────────
map("n", "U", "<C-r>", { desc = "Redo" })
map("n", "Q", "<Nop>", { desc = "Disable Ex mode" })
map("n", "<C-z>", "<Nop>", { desc = "Disable suspend" })
map({ "i", "v" }, "<C-c>", "<Esc>", { desc = "Normalise Ctrl-c to Escape" })

-- ── Saving & Quitting ────────────────────────────────────────────────
map("i", "<C-s>", "<C-o><cmd>update<CR>", { desc = "Save buffer" })
map({ "n", "v" }, "<C-s>", "<cmd>update<CR>", { desc = "Save buffer" })
map("n", "<leader>qq", "<cmd>confirm q<CR>", { desc = "Quit window" })
map("n", "<leader>qw", "<cmd>wq<CR>", { desc = "Save and quit" })
map("n", "<leader>qa", "<cmd>qa<CR>", { desc = "Quit all" })

-- ── Insert Mode ──────────────────────────────────────────────────────
local smart_enter = require("smart_enter")
map("i", "<CR>", smart_enter.cr, { expr = true, desc = "Smart Enter (continue lists & comments)" })
map("i", "<S-CR>", smart_enter.shift_cr, { expr = true, desc = "Shift-Enter (newline without continuation)" })
map("i", "<M-CR>", smart_enter.shift_cr, { expr = true, desc = "Alt-Enter (newline without continuation)" })

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
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centred)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centred)" })

-- ── Search ───────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>h", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "n", "nzzzv", { desc = "Next search result (centred)" })
map("n", "N", "Nzzzv", { desc = "Prev search result (centred)" })
map("n", "*", "*zz", { desc = "Search word forward (centred)" })
map("n", "#", "#zz", { desc = "Search word backward (centred)" })

-- ── Windows ──────────────────────────────────────────────────────────
map("n", "<leader>wv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>ws", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>wq", "<C-w>c", { desc = "Close window" })
map("n", "<leader>wo", "<C-w>o", { desc = "Only window" })
map("n", "<leader>wz", function()
	if vim.t.zoomed then
		vim.cmd("tabclose")
		vim.t.zoomed = false
	else
		vim.cmd("tab split")
		vim.t.zoomed = true
	end
end, { desc = "Toggle maximise/zoom window" })
map("n", "<leader>w=", "<C-w>=", { desc = "Equalise windows" })
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
-- [q/]q and [l/]l are built-in defaults now (and honour a count), so only
-- the <leader> variants are kept here.
map("n", "<leader>qo", "<cmd>copen<CR>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "<leader>qf", function()
	vim.cmd(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and "cclose" or "copen")
end, { desc = "Toggle quickfix list" })
map("n", "<leader>ql", "<cmd>lopen<CR>", { desc = "Open location list" })
map("n", "<leader>qL", "<cmd>lclose<CR>", { desc = "Close location list" })

-- ── Diagnostics ──────────────────────────────────────────────────────

map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- `float = true` in vim.diagnostic.jump() is deprecated (removed in 0.14);
-- `on_jump` is the replacement and shows the same float at the destination.
local function diag_jump(count, extra)
	vim.diagnostic.jump(vim.tbl_extend("force", {
		count = count,
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
		end,
	}, extra or {}))
end
map("n", "]d", function()
	diag_jump(1)
end, { desc = "Next diagnostic" })
map("n", "[d", function()
	diag_jump(-1)
end, { desc = "Previous diagnostic" })
map("n", "]e", function()
	diag_jump(1, { severity = vim.diagnostic.severity.ERROR })
end, { desc = "Next error" })
map("n", "[e", function()
	diag_jump(-1, { severity = vim.diagnostic.severity.ERROR })
end, { desc = "Previous error" })

-- ── Toggles ──────────────────────────────────────────────────────────
map("n", "<leader>tw", "<cmd>set wrap!<CR>", { desc = "Toggle wrap" })
map("n", "<leader>ts", "<cmd>set spell!<CR>", { desc = "Toggle spell" })
map("n", "<leader>tn", function()
	-- Track intent in a global so the InsertEnter/InsertLeave autocmds don't
	-- silently re-enable relative numbers after this toggle.
	local enabled = not (vim.g.relativenumber_enabled ~= false)
	vim.g.relativenumber_enabled = enabled
	vim.opt.relativenumber = enabled
	vim.notify("Relative numbers " .. (enabled and "enabled" or "disabled"))
end, { desc = "Toggle relative numbers" })
map("n", "<leader>td", function()
	local new_state = not vim.diagnostic.is_enabled()
	vim.diagnostic.enable(new_state)
	local ok, tid = pcall(require, "tiny-inline-diagnostic")
	if ok then
		if new_state then
			tid.enable()
		else
			tid.disable()
		end
	end
end, { desc = "Toggle diagnostics" })
map("n", "<leader>tD", function()
	local ok, tid = pcall(require, "tiny-inline-diagnostic")
	if ok then
		tid.toggle()
	end
end, { desc = "Toggle inline diagnostics" })
map("n", "<leader>ti", function()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
end, { desc = "Toggle inlay hints" })
map("n", "<leader>tc", function()
	vim.g.minicursorword_disable = not vim.g.minicursorword_disable
	vim.notify("Cursor word highlighting " .. (vim.g.minicursorword_disable and "disabled" or "enabled"))
end, { desc = "Toggle cursor word" })

-- ── LSP (non-attach) ────────────────────────────────────────────────
map("n", "<leader>li", "<cmd>checkhealth vim.lsp<CR>", { desc = "LSP info" })
map("n", "<leader>lr", function()
	if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
		vim.notify("No LSP client attached to this buffer", vim.log.levels.WARN)
		return
	end
	vim.cmd("lsp restart")
end, { desc = "Restart LSP" })
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
map("n", "<leader>gl", "<cmd>FzfLua git_commits<CR>", { desc = "Git log" })
map("n", "<leader>gS", "<cmd>FzfLua git_status<CR>", { desc = "Git status (picker)" })
map("n", "<leader>gL", "<cmd>FzfLua git_bcommits<CR>", { desc = "Git log (current file)" })
map("n", "<leader>gB", "<cmd>FzfLua git_branches<CR>", { desc = "Git branches" })
map("n", "<leader>gF", "<cmd>FzfLua git_stash<CR>", { desc = "Git stash" })

-- ── Miscellaneous ────────────────────────────────────────────────────
map("n", "<leader>cd", "<cmd>cd %:p:h<CR>", { desc = "Change to file directory" })
-- `zz` intentionally left as the built-in "centre cursor"; use `za` to toggle folds.
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
map("n", "<C-.>", "@@", { desc = "Repeat last macro" })
