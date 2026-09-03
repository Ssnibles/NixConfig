local M = {}

M.core = {
	"plugins.treesitter",
	"plugins.completion",
	"plugins.lsp",
	"plugins.editor",
	"plugins.format",
	"plugins.mini",
	"plugins.fzf",
	"plugins.navigation",
	"plugins.ui",
	"plugins.fidget",
	"plugins.terminal",
	"plugins.lint",
	"plugins.sshinator",
	"plugins.indentinator",
	"plugins.zline",
	"plugins.inc-rename",
}

M.deferred = {
	{ "plugins.typst-snippets", ft = "typst" },
	{ "plugins.nix-snippets", ft = "nix" },
	{ "plugins.java-snippets", ft = "java" },
	{ "plugins.rust", ft = "rust" },
	{ "plugins.c", ft = { "c", "cpp", "objc", "objcpp", "cuda" } },
	{ "plugins.neogit", cmd = "Neogit" },
	{ "plugins.dap", keys = { "<leader>mb", "<leader>mc" } },
}

return M
