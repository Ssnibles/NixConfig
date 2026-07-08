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
}

M.deferred = {
	"plugins.trouble",
	"plugins.neogit",
	"plugins.dap",
}

return M
