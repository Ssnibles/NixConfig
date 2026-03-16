-- =============================================================================
-- UI Plugin Configuration
-- =============================================================================
-- Miscellaneous UI plugins: which-key, gitsigns, oil, autopairs, markview,
-- noice, and fidget. Each provides visual enhancements without redundancy.
-- ── which-key ──────────────────────────────────────────────────────────────
require("which-key").setup({
	win = { border = "rounded" },
	plugins = {
		marks = true,
		registers = true,
		spelling = { enabled = true, suggestions = 20 },
		presets = {
			operators = true,
			motions = true,
			text_objects = true,
			windows = true,
			nav = true,
			z = true,
			g = true,
		},
	},
})
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
	-- Prevent visual glitches with sign column
	signcolumn = true,
	numhl = false,
	linehl = false,
	word_diff = false,
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
	-- Prevent visual glitches in oil buffers
	win_options = {
		cursorline = false,
	},
})
-- ── nvim-autopairs ─────────────────────────────────────────────────────────
-- Automatic bracket, quote, and parenthesis pairing
require("nvim-autopairs").setup({
	check_ts = true,
	ts_config = { lua = { "string" }, javascript = { "template_string" } },
	fast_wrap = { map = "<M-e>" },
	-- Prevent conflicts with completion
	completion = true,
})
-- ── markview ───────────────────────────────────────────────────────────────
-- Markdown preview with rendered formatting
require("markview").setup({
	modes = { "n", "no", "c" },
	hybrid_modes = { "n", "no" },
})
-- ── noice ──────────────────────────────────────────────────────────────────
-- Modern command-line and notification UI (fidget handles LSP progress)
require("noice").setup({
	-- Disable noice notifications (fidget handles LSP progress)
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
	-- Prevent visual glitches with cmdline
	cmdline = {
		enabled = true,
		view = "cmdline",
	},
})
-- ── fidget ─────────────────────────────────────────────────────────────────
-- LSP progress indicator in top-right corner (primary notification handler)
require("fidget").setup({
	notification = {
		window = { winblend = 0, border = "none" },
		override_vim_notify = true,
	},
	progress = {
		display = {
			done_icon = "✓",
			done_ttl = 3000,
		},
	},
	-- Prevent conflicts with noice
	integration = {
		["nvim-notify"] = { enabled = false },
	},
})
