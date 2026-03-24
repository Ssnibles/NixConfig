-- =============================================================================
-- Keymap Configuration
-- =============================================================================
-- Centralized key bindings for navigation, editing, and plugin integration.
-- Uses leader key (space) for most commands to avoid conflicts.
--
-- Note: git hunk keymaps (]g, [g, <leader>g*) are set inside gitsigns
-- on_attach in plugins/ui.lua so they are buffer-local and only active in
-- git-tracked files.
--
-- Note: LSP keymaps (gd, K, <leader>a, etc.) are set inside lsp.lua's
-- on_attach for the same reason.
-- =============================================================================

local map = function(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- ── General ────────────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")
map("i", "jk", "<Esc>", "Exit insert mode")
map("n", "U", "<C-r>", "Redo")
map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")

-- ── Navigation ─────────────────────────────────────────────────────────────
map("n", "j", "gj", "Down (visual line)")
map("n", "k", "gk", "Up (visual line)")
map("n", "<C-d>", "<C-d>zz", "Scroll down (centred)")
map("n", "<C-u>", "<C-u>zz", "Scroll up (centred)")
map("n", "n", "nzzzv", "Next match (centred)")
map("n", "N", "Nzzzv", "Prev match (centred)")

-- ── Clipboard ──────────────────────────────────────────────────────────────
map("x", "<leader>p", '"_dP', "Paste without yanking selection")
map({ "n", "v" }, "<leader>D", '"_d', "Delete without yanking")

-- ── Windows ────────────────────────────────────────────────────────────────
map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "<leader>we", "<C-w>=", "Equalise splits")
map("n", "<leader>wm", "<C-w>_<C-w>|", "Maximise window")

-- Keybindings for vim-tmux-navigator
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<cr>", "Navigate Left")
map("n", "<C-j>", "<cmd>TmuxNavigateDown<cr>", "Navigate Down")
map("n", "<C-k>", "<cmd>TmuxNavigateUp<cr>", "Navigate Up")
map("n", "<C-l>", "<cmd>TmuxNavigateRight<cr>", "Navigate Right")

-- ── Buffers ────────────────────────────────────────────────────────────────
map("n", "<Tab>", "<cmd>bnext<CR>", "Next buffer")
map("n", "<S-Tab>", "<cmd>bprevious<CR>", "Previous buffer")

-- ── Quickfix ───────────────────────────────────────────────────────────────
map("n", "<leader>qo", "<cmd>copen<CR>", "Open quickfix")
map("n", "<leader>qc", "<cmd>cclose<CR>", "Close quickfix")
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprevious<CR>", "Prev quickfix item")
map("n", "]l", "<cmd>lnext<CR>", "Next location item")
map("n", "[l", "<cmd>lprevious<CR>", "Prev location item")

-- ── Diagnostics ────────────────────────────────────────────────────────────
map("n", "<leader>dd", vim.diagnostic.open_float, "Show diagnostic float")
map("n", "<leader>dq", vim.diagnostic.setloclist, "Diagnostics → loclist")
map("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, "Next diagnostic")
map("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, "Prev diagnostic")
map("n", "]e", function()
	vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Next error")
map("n", "[e", function()
	vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, "Prev error")

-- ── File Navigation ────────────────────────────────────────────────────────
map("n", "-", "<cmd>Oil<CR>", "Open Oil")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil")

-- ── LSP (non-buffer-local helpers) ────────────────────────────────────────
map("n", "<leader>li", "<cmd>LspInfo<CR>", "LSP info")
map("n", "<leader>lr", "<cmd>LspRestart<CR>", "LSP restart")

-- ── Toggles ────────────────────────────────────────────────────────────────
map("n", "<leader>tw", "<cmd>set wrap!<CR>", "Toggle wrap")
map("n", "<leader>ts", "<cmd>set spell!<CR>", "Toggle spell")
map("n", "<leader>tl", "<cmd>set list!<CR>", "Toggle listchars")
map("n", "<leader>tn", "<cmd>set relativenumber!<CR>", "Toggle relative numbers")
map("n", "<leader>tc", function()
	require("mini.cursorword").toggle()
end, "Toggle cursorword")
map("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }))
end, "Toggle inlay hints")
