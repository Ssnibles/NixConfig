-- fzf-lua — fuzzy finder for files, grep, LSP, git, and more.

local fzf = require("fzf-lua")

fzf.setup({
	winopts = {
		height = 0.92,
		width = 0.92,
		border = "rounded",
		preview = {
			layout = "vertical",
			vertical = "right:55%",
			scrollbar = true,
			border = "border-left",
		},
	},

	-- fd: respects .gitignore, hidden files, skips noise dirs
	files = {
		cmd = "fd --type f --hidden --exclude .git --exclude node_modules",
	},

	-- rg: no colour codes, include hidden, skip .git/node_modules
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

	-- Consistent key overrides across all pickers
	keymap = {
		fzf = {
			["ctrl-q"] = "select-all+accept", -- send all to quickfix
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

-- ── Keymaps ───────────────────────────────────────────────────────────────
local map = function(lhs, fn, desc)
	vim.keymap.set("n", lhs, fn, { desc = desc })
end

-- Files
map("<leader>ff", fzf.files, "Find files")
map("<leader>fr", fzf.oldfiles, "Recent files")
map("<leader>fb", fzf.buffers, "Find buffers")

-- Search
map("<leader>fg", fzf.live_grep, "Live grep")
map("<leader>fw", fzf.grep_cword, "Grep word under cursor")
map("<leader>fW", fzf.grep_cWORD, "Grep WORD under cursor")
map("<leader>f/", fzf.blines, "Search current buffer")
map("<leader>f?", fzf.search_history, "Search history")

-- LSP
map("<leader>fs", fzf.lsp_document_symbols, "Document symbols")
map("<leader>fS", fzf.lsp_workspace_symbols, "Workspace symbols")
map("<leader>fd", fzf.diagnostics_document, "Buffer diagnostics")
map("<leader>fD", fzf.diagnostics_workspace, "Workspace diagnostics")

-- Git
map("<leader>gc", fzf.git_commits, "Git commits")
map("<leader>gC", fzf.git_bcommits, "Git buffer commits")
map("<leader>gt", fzf.git_status, "Git status")

-- Meta
map("<leader>fh", fzf.help_tags, "Help tags")
map("<leader>fk", fzf.keymaps, "Keymaps")
map("<leader>fc", fzf.commands, "Commands")
map("<leader>fm", fzf.marks, "Marks")
map("<leader>fq", fzf.quickfix, "Quickfix list")

-- Resume last picker
map("<leader>f.", fzf.resume, "Resume last picker")
