-- ============================================================================
-- NEOVIM ENTRY POINT
-- Load order matters:
--   1. options        — vim.opt + vim.g.mapleader before anything else
--   2. keymaps        — global keymaps (buffer-local ones live in lsp.lua)
--   3. autocommands   — event-driven behaviour
--   4. plugins        — each file requires + configures one plugin group
-- ============================================================================

require("options")
require("keymaps")
require("autocommands")

require("plugins.lsp")
require("plugins.fzf")
require("plugins.conform")
require("plugins.lualine")
require("plugins.ibl")
require("plugins.neoscroll")
require("plugins.blink")

-- ============================================================================
-- COLORSCHEME
-- Set after plugins so vague's highlights overwrite plugin defaults.
-- ============================================================================
vim.cmd.colorscheme("vague")

-- ============================================================================
-- HIGHLIGHT OVERRIDES
-- Loaded after the colorscheme so vague doesn't reset custom groups.
-- ============================================================================
require("plugins.highlights")

-- ============================================================================
-- DIAGNOSTICS
-- ============================================================================
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
	float = { border = "rounded", source = "always" },
})

-- ============================================================================
-- SIMPLE PLUGIN SETUPS
-- Plugins that only need a one-liner live here to avoid cluttering plugins/.
-- ============================================================================

-- which-key: show pending keybind completions (v3+ API uses `win`, not `window`)
require("which-key").setup({ win = { border = "rounded" } })

-- gitsigns: git diff in the gutter + hunk navigation/staging.
require("gitsigns").setup()

-- markview: render markdown inline (tables, headings, etc.)
require("markview").setup()

-- oil: edit the filesystem like a buffer.
require("oil").setup({ view_options = { show_hidden = true } })

-- nvim-autopairs: auto-close brackets and quotes; treesitter-aware.
require("nvim-autopairs").setup({ check_ts = true })

-- luasnip: load VS Code-format snippets from friendly-snippets.
require("luasnip.loaders.from_vscode").lazy_load()

-- fidget: LSP progress spinner in the bottom-right corner.
require("fidget").setup({
	notification = {
		window = { winblend = 0, border = "none" },
	},
})

-- noice: replaces the command-line UI and adds better hover styling.
-- notify + messages are off because fidget/gitsigns handle those.
require("noice").setup({
	notify = { enabled = false },
	messages = { enabled = false },
	lsp = {
		progress = { enabled = false }, -- fidget handles this
		override = {
			-- Render hover docs and signature help via noice's markdown engine.
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
	},
})

-- ============================================================================
-- STATUSCOL (custom status column)
-- ============================================================================
local builtin = require("statuscol.builtin")
require("statuscol").setup({
	relculright = true,
	segments = {
		{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
		{ text = { "%s" }, click = "v:lua.ScSa" },
		{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
	},
	ft_ignore = { "neo-tree", "lazy", "mason" },
})

-- ============================================================================
-- TREESITTER
-- ============================================================================
local ok, ts = pcall(require, "nvim-treesitter.configs")
if ok then
	ts.setup({
		highlight = { enable = true },
		indent = { enable = true },
	})
end
