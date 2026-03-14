-- ============================================================================
-- FZF-LUA
-- Fast fuzzy finder for files, grep, LSP symbols, etc.
-- Faster than telescope for large codebases; shares the same picker API.
-- ============================================================================
local fzf = require("fzf-lua")

fzf.setup({
	winopts = {
		backdrop = "NormalFloat",
		height = 0.95,
		width = 0.95,
		border = "rounded",
		preview = {
			layout = "vertical",
			vertical = "right:60%", -- Preview panel on the right, 60% width
			scrollbar = true,
		},
	},

	-- fd: respect .gitignore, include hidden files, skip common noise dirs.
	files = {
		cmd = "fd --type f --hidden --exclude .git --exclude node_modules",
	},

	-- rg: no colour codes (fzf applies its own), include hidden files,
	-- skip .git/node_modules, and output in the standard location format.
	grep = {
		rg_opts = "--color=never --hidden --glob '!{.git,node_modules}' --no-heading --line-number --column",
	},
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Find files in the current project root.
vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })

-- Live grep: search file contents in real time.
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })

-- Search recently accessed files.
vim.keymap.set("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files" })

-- Find open buffers.
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Find buffers" })

-- LSP: symbols in current buffer and workspace.
vim.keymap.set("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>fS", fzf.lsp_workspace_symbols, { desc = "Workspace symbols" })
