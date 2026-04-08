-- fzf-lua: fuzzy finder

local fzf = require("fzf-lua")
fzf.setup({
	winopts = {
		height = 0.9,
		width = 0.9,
		border = "rounded",
		preview = { layout = "vertical", vertical = "right:55%" },
	},
	files = { cmd = "fd --type f --hidden --exclude .git" },
	grep = { rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --glob '!.git'" },
})

local map = vim.keymap.set
map("n", "<leader>ff", fzf.files, { desc = "Find files" })
map("n", "<leader>fr", fzf.oldfiles, { desc = "Recent files" })
map("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
map("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
map("n", "<leader>fw", fzf.grep_cword, { desc = "Grep word" })
map("n", "<leader>f/", fzf.blines, { desc = "Search buffer" })
map("n", "<leader>fs", fzf.lsp_document_symbols, { desc = "Document symbols" })
map("n", "<leader>fS", fzf.lsp_workspace_symbols, { desc = "Workspace symbols" })
map("n", "<leader>fd", fzf.diagnostics_document, { desc = "Diagnostics" })
map("n", "<leader>fh", fzf.help_tags, { desc = "Help" })
map("n", "<leader>fk", fzf.keymaps, { desc = "Keymaps" })
map("n", "<leader>f.", fzf.resume, { desc = "Resume" })
map("n", "<leader>gc", fzf.git_commits, { desc = "Git commits" })
map("n", "<leader>gt", fzf.git_status, { desc = "Git status" })
