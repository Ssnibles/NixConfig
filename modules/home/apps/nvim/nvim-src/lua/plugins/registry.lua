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
	"plugins.lint",
	"plugins.dashboard",
}

M.deferred = {
	"plugins.trouble",
	"plugins.neogit",
	"plugins.dap",
	"plugins.terminal",
	"plugins.focus",
}

return M
