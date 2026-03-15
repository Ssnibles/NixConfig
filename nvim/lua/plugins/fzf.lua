-- =============================================================================
-- fzf-lua Configuration
-- =============================================================================
-- Fuzzy finder for files, grep, LSP symbols, git history, and more.
-- Uses fd for file search and rg for grep with optimized arguments.

local fzf = require("fzf-lua")
fzf.setup({
	-- Window appearance and layout
	winopts = {
		height = 0.92,
		width = 0.92,
		border = "rounded",
		preview = {
			layout = "vertical",
			vertical = "right:55%",
			scrollbar = true,
			border = "none",
		},
	},

	-- File search with fd (respects .gitignore, includes hidden files)
	files = {
		cmd = "fd --type f --hidden --exclude .git --exclude node_modules",
	},

	-- Grep with ripgrep (no color codes, smart case)
	grep = {
		rg_opts = table.concat({
			"--color=never",
			"--hidden",
			"--glob '!{.git,node_modules}'",
			"--no-heading",
			"--line-number",
			"--column",
			"--smart-case",
		}, " "),
	},

	-- Keybindings for fzf interface
	keymap = {
		fzf = {
			["ctrl-q"] = "select-all+accept",
			["ctrl-u"] = "half-page-up",
			["ctrl-d"] = "half-page-down",
		},
		builtin = {
			["<C-/>"] = "toggle-help",
			["<C-p>"] = "toggle-preview",
			["<C-f>"] = "preview-page-down",
			["<C-b>"] = "preview-page-up",
		},
	},
})

-- ── Keymaps ────────────────────────────────────────────────────────────────
local map = function(lhs, fn, desc)
	vim.keymap.set("n", lhs, fn, { desc = desc })
end

-- File search
map("<leader>ff", fzf.files, "Find files")
map("<leader>fr", fzf.oldfiles, "Recent files")
map("<leader>fb", fzf.buffers, "Find buffers")

-- Text search
map("<leader>fg", fzf.live_grep, "Live grep")
map("<leader>fw", fzf.grep_cword, "Grep word under cursor")
map("<leader>fW", fzf.grep_cWORD, "Grep WORD under cursor")
map("<leader>f/", fzf.blines, "Search current buffer")
map("<leader>f?", fzf.search_history, "Search history")

-- LSP symbols and diagnostics
map("<leader>fs", fzf.lsp_document_symbols, "Document symbols")
map("<leader>fS", fzf.lsp_workspace_symbols, "Workspace symbols")
map("<leader>fd", fzf.diagnostics_document, "Buffer diagnostics")
map("<leader>fD", fzf.diagnostics_workspace, "Workspace diagnostics")

-- Git operations
map("<leader>gc", fzf.git_commits, "Git commits")
map("<leader>gC", fzf.git_bcommits, "Git buffer commits")
map("<leader>gt", fzf.git_status, "Git status")

-- Meta commands
map("<leader>fh", fzf.help_tags, "Help tags")
map("<leader>fk", fzf.keymaps, "Keymaps")
map("<leader>fc", fzf.commands, "Commands")
map("<leader>fm", fzf.marks, "Marks")
map("<leader>fq", fzf.quickfix, "Quickfix list")
map("<leader>f.", fzf.resume, "Resume last picker")
