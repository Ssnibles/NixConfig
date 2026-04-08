-- Neovim configuration entry point

-- Core settings
require("options")
require("keymaps")
require("autocmds")

-- Diagnostics
vim.diagnostic.config({
	virtual_text = false,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚",
			[vim.diagnostic.severity.WARN] = "󰀪",
			[vim.diagnostic.severity.HINT] = "󰌶",
			[vim.diagnostic.severity.INFO] = "󰋽",
		},
	},
	underline = true,
	severity_sort = true,
	float = { border = "rounded", source = true },
	update_in_insert = false,
})

-- Theme
require("theme").setup()

-- Plugins (loaded via Nix runtimepath)
require("plugins.treesitter")
require("plugins.completion")
require("plugins.lsp")
require("plugins.editor")
require("plugins.ui")
require("plugins.mini")
require("plugins.fzf")
require("plugins.neogit")
require("plugins.navigation")

-- Final touches
vim.opt.cmdheight = 0
