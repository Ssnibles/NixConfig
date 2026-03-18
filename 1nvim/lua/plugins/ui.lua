-- =============================================================================
-- UI Plugin Configuration
-- =============================================================================
-- Miscellaneous UI plugins: which-key, gitsigns, oil, autopairs, markview,
-- noice, and fidget. Each provides visual enhancements without redundancy.

-- ── which-key ──────────────────────────────────────────────────────────────
local which_key_ok = pcall(require, "which-key")
if which_key_ok then
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
end

-- ── gitsigns ───────────────────────────────────────────────────────────────
local gitsigns_ok = pcall(require, "gitsigns")
if gitsigns_ok then
	require("gitsigns").setup({
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		current_line_blame = false,
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "eol",
			delay = 600,
			ignore_whitespace = true,
		},
		current_line_blame_formatter = " <author>, <author_time:%Y-%m-%d> · <summary>",
		preview_config = { border = "rounded" },
		signcolumn = true,
		numhl = false,
		linehl = false,
		word_diff = false,
	})
end

-- ── Oil ────────────────────────────────────────────────────────────────────
local oil_ok = pcall(require, "oil")
if oil_ok then
	require("oil").setup({
		view_options = {
			show_hidden = true,
			is_always_hidden = function(name, _)
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
		win_options = {
			cursorline = false,
		},
	})
end

-- ── nvim-autopairs ─────────────────────────────────────────────────────────
local autopairs_ok = pcall(require, "nvim-autopairs")
if autopairs_ok then
	require("nvim-autopairs").setup({
		check_ts = true,
		ts_config = { lua = { "string" }, javascript = { "template_string" } },
		fast_wrap = { map = "<M-e>" },
		completion = true,
	})
end

-- ── markview ───────────────────────────────────────────────────────────────
local markview_ok = pcall(require, "markview")
if markview_ok then
	require("markview").setup({
		modes = { "n", "no", "c" },
		hybrid_modes = { "n", "no" },
	})
end

-- ── noice ──────────────────────────────────────────────────────────────────
-- Modern command-line and notification UI
-- Cmdline view replaces the statusline area at the bottom (not a popup)
local noice_ok = pcall(require, "noice")
if noice_ok then
	require("noice").setup({
		-- Disable noice notifications (fidget handles LSP progress)
		notify = { enabled = false },
		-- Messages shown in mini view
		messages = {
			enabled = true,
			view = "mini",
		},
		-- LSP integration
		lsp = {
			progress = { enabled = false },
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
			hover = { enabled = true },
			signature = { enabled = true },
		},
		-- Command line replacement - displays in statusline area at bottom
		cmdline = {
			enabled = true,
			-- Use 'cmdline' view to replace statusline area (not popup)
			view = "cmdline",
			-- Format patterns for different command types
			format = {
				cmdline = { pattern = "^:", icon = "", lang = "vim" },
				search_down = { pattern = "^/", icon = " ", lang = "regex" },
				search_up = { pattern = "^?", icon = " ", lang = "regex" },
				filter = { pattern = "^:%s*!", icon = "", lang = "bash" },
				lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },
				help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖" },
				input = { view = "cmdline_input", icon = "󰥻 " },
			},
		},
		-- Search highlighting and incrementality
		inc_rename = { enabled = true },
		-- Presets for common UI patterns
		presets = {
			bottom_search = true, -- Search appears at bottom (statusline area)
			command_palette = false, -- Don't use command palette popup
			long_message_to_split = true,
			inc_rename = true,
			lsp_doc_border = true,
		},
		-- Routes to suppress or redirect messages
		routes = {
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" },
						{ find = "; after #%d+" },
						{ find = "; before #%d+" },
						{ find = "fewer lines" },
					},
				},
				view = "mini",
			},
		},
	})
end

-- ── fidget ─────────────────────────────────────────────────────────────────
local fidget_ok = pcall(require, "fidget")
if fidget_ok then
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
		integration = {
			["nvim-notify"] = { enabled = false },
		},
	})
end
