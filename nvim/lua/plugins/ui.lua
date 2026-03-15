-- =============================================================================
-- UI Plugin Configuration
-- =============================================================================
-- Miscellaneous UI plugins: which-key, gitsigns, oil, autopairs, markview,
-- noice, and fidget. Each provides visual enhancements without redundancy.

-- ── which-key ──────────────────────────────────────────────────────────────
-- Show keybinding hints after leader key press
require("which-key").setup({ win = { border = "rounded" } })

-- ── gitsigns ───────────────────────────────────────────────────────────────
-- Git integration with sign column indicators and inline blame
require("gitsigns").setup({
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = "" },
		topdelete = { text = "" },
		changedelete = { text = "▎" },
		untracked = { text = "▎" },
	},
	-- Inline blame disabled by default (toggle with <leader>gb)
	current_line_blame = false,
	current_line_blame_opts = {
		virt_text = true,
		virt_text_pos = "eol",
		delay = 600,
		ignore_whitespace = true,
	},
	current_line_blame_formatter = " <author>, <author_time:%Y-%m-%d> · <summary>",
	preview_config = { border = "rounded" },
})

-- ── Oil ────────────────────────────────────────────────────────────────────
-- File explorer that edits directories as buffers
require("oil").setup({
	view_options = {
		show_hidden = true,
		is_always_hidden = function(name, _)
			-- Hide .git directory but show other dotfiles
			return name == ".git"
		end,
	},
	float = { border = "rounded" },
	keymaps = {
		["<C-s>"] = false,
		["<C-h>"] = false,
		["<C-v>"] = { "actions.select", opts = { vertical = true } },
		["<C-x>"] = { "actions.select", opts = { horizontal = true } },
	},
})

-- ── nvim-autopairs ─────────────────────────────────────────────────────────
-- Automatic bracket, quote, and parenthesis pairing
require("nvim-autopairs").setup({
	check_ts = true,
	ts_config = { lua = { "string" }, javascript = { "template_string" } },
	fast_wrap = { map = "<M-e>" },
})

-- ── markview ───────────────────────────────────────────────────────────────
-- Markdown preview with rendered formatting
require("markview").setup()

-- ── noice ──────────────────────────────────────────────────────────────────
-- Modern command-line and notification UI
require("noice").setup({
	notify = { enabled = false },
	messages = { enabled = true, view = "mini" },
	lsp = {
		progress = { enabled = false },
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
		hover = { enabled = true },
		signature = { enabled = true },
	},
	presets = {
		bottom_search = true,
		command_palette = false,
		long_message_to_split = true,
		inc_rename = true,
	},
})

-- ── fidget ─────────────────────────────────────────────────────────────────
-- LSP progress indicator in top-right corner
require("fidget").setup({
	notification = { window = { winblend = 0, border = "none" } },
})
