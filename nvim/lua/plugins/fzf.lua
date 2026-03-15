-- fzf-lua — fuzzy finder for files, grep, LSP symbols, etc.

local fzf = require("fzf-lua")

fzf.setup({
	winopts = {
		height = 0.95,
		width = 0.95,
		border = "rounded",
		preview = {
			layout = "vertical",
			vertical = "right:60%",
			scrollbar = true,
		},
	},
	-- fd: respects .gitignore, includes hidden files, skips noise dirs.
	files = {
		cmd = "fd --type f --hidden --exclude .git --exclude node_modules",
	},
	-- rg: no colour codes, include hidden, skip .git/node_modules.
	grep = {
		rg_opts = "--color=never --hidden --glob '!{.git,node_modules}' --no-heading --line-number --column",
	},
})

-- ── Keymaps ───────────────────────────────────────────────────────────────
local map = function(lhs, fn, desc)
	vim.keymap.set("n", lhs, fn, { desc = desc })
end

map("<leader>ff", fzf.files, "Find files")
map("<leader>fg", fzf.live_grep, "Live grep")
map("<leader>fr", fzf.oldfiles, "Recent files")
map("<leader>fb", fzf.buffers, "Find buffers")
map("<leader>fs", fzf.lsp_document_symbols, "Document symbols")
map("<leader>fS", fzf.lsp_workspace_symbols, "Workspace symbols")
