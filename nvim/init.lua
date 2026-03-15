-- Load order:
--   1. options       – vim.opt + mapleader (must precede everything)
--   2. keymaps       – global mappings
--   3. autocommands  – event hooks
--   4. colorscheme   – set before plugins so overrides stick
--   5. plugins       – each file requires + configures one plugin group

require("options")
require("keymaps")
require("autocommands")

-- Set colorscheme before plugins so highlight overrides in completion.lua
-- are not reset by vague's own setup when it initialises.
vim.cmd.colorscheme("vague")

-- completion.lua runs first after the colorscheme because it also sets all
-- highlight group overrides (blink menus, floats, diagnostic line tints, ibl).
-- Those groups must exist before any other plugin that references them.
require("plugins.completion") -- blink.cmp + luasnip + all hl overrides

require("plugins.ui") -- which-key, gitsigns, oil, autopairs, markview, noice
require("plugins.lsp") -- LSP servers (uses capabilities from blink, already loaded)
require("plugins.fzf") -- fzf-lua
require("plugins.conform") -- formatter
require("plugins.treesitter") -- treesitter
require("plugins.statusline") -- lualine + ibl + neoscroll + statuscol + fidget

-- Hide cmdline bar when inactive (cleaner look).
vim.opt.cmdheight = 0

-- Diagnostics
vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
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
})
