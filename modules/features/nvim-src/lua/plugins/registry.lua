local M = {}

M.core = {
	"plugins.treesitter",
	"plugins.completion",
	"plugins.lsp",
	"plugins.editor",
	"plugins.mini",
	"plugins.fzf",
	"plugins.navigation",
	"plugins.ui",
	"plugins.terminal",
	"plugins.lint",
	"plugins.rust",
	"plugins.sshinator",
	"plugins.java-snippets",
	"plugins.typst-snippets",
}

M.deferred = {
	"plugins.trouble",
	"plugins.neogit",
	"plugins.dap",
}

return M
