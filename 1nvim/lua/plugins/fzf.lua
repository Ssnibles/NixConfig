-- =============================================================================
-- fzf-lua
-- =============================================================================
if not pcall(require, "fzf-lua") then
	return
end

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
			border = "none",
		},
	},
	files = {
		cmd = "fd --type f --hidden --exclude .git --exclude node_modules",
	},
	grep = {
		rg_opts = "--color=never --hidden --glob '!{.git,node_modules}' --no-heading --line-number --column --smart-case",
	},
})

local map = function(lhs, fn, desc)
	vim.keymap.set("n", lhs, fn, { desc = desc })
end

map("<leader>ff", fzf.files, "Find files")
map("<leader>fr", fzf.oldfiles, "Recent files")
map("<leader>fb", fzf.buffers, "Find buffers")
map("<leader>fg", fzf.live_grep, "Live grep")
map("<leader>fw", fzf.grep_cword, "Grep word")
map("<leader>f/", fzf.blines, "Search buffer")
map("<leader>fs", fzf.lsp_document_symbols, "Document symbols")
map("<leader>fS", fzf.lsp_workspace_symbols, "Workspace symbols")
map("<leader>fd", fzf.diagnostics_document, "Buffer diagnostics")
map("<leader>fD", fzf.diagnostics_workspace, "Workspace diagnostics")
map("<leader>gc", fzf.git_commits, "Git commits")
map("<leader>gt", fzf.git_status, "Git status")
map("<leader>fh", fzf.help_tags, "Help tags")
map("<leader>fk", fzf.keymaps, "Keymaps")
map("<leader>f.", fzf.resume, "Resume")
