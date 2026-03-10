-- ============================================================================
-- MAIN CONFIGURATION
-- ============================================================================

-- Load standard modules
require("options")
require("keymaps")
require("autocommands")

-- Load Plugins from the plugins dir
require("plugins.lsp")
require("plugins.fzf")
require("plugins.conform")

-- ============================================================================
-- COLORSCHEME
-- ============================================================================
vim.cmd.colorscheme("catppuccin-mocha")

-- ============================================================================
-- DIAGNOSTICS & UI
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
-- PLUGIN SETUPS (Directly initialized plugins)
-- ============================================================================
require("which-key").setup({ window = { border = "rounded" } })
require("gitsigns").setup()
require("markview").setup()
require("oil").setup({ view_options = { show_hidden = true } })
require("nvim-autopairs").setup({ check_ts = true })
require("luasnip.loaders.from_vscode").lazy_load()
require("fidget").setup({ notification = { window = { winblend = 0, border = "none" } } })

require("noice").setup({
	-- Completely disable the notify handler so it doesn't interfere
	notify = {
		enabled = false,
	},
	-- Disable LSP progress messages as fidget handles them
	lsp = {
		progress = { enabled = false },
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
			["cmp.entry.get_documentation"] = true,
		},
	},
	-- Keep command line UI, but disable message popups
	messages = { enabled = false },
})

-- Blink.cmp setup
require("blink.cmp").setup({
	keymap = {
		preset = "super-tab",
	},
	cmdline = {
		keymap = {
			["<Tab>"] = { "accept", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
		},
		-- Add this completion block inside cmdline
		completion = {
			menu = {
				auto_show = true,
				draw = {
					columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
				},
			},
			ghost_text = { enabled = true },
		},
	},
	completion = {
		menu = { auto_show = true },
		ghost_text = { enabled = true },
	},
	sources = {
		default = { "lsp", "path", "snippets", "buffer" },
	},
})

-- Statuscol setup
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

-- Treesitter
local ok, ts = pcall(require, "nvim-treesitter.configs")
if ok then
	ts.setup({ highlight = { enable = true }, indent = { enable = true } })
end
