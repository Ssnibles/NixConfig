-- =============================================================================
-- UI Components & Enhancements
-- =============================================================================
local loader = require("lib.loader")

loader.setup("gitsigns", {
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = " " },
		topdelete = { text = " " },
		changedelete = { text = "▎" },
	},
	preview_config = { border = "rounded" },
	on_attach = function(bufnr)
		local gs = package.loaded.gitsigns
		local function map(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
		end
		map("n", "]g", gs.next_hunk, "Next hunk")
		map("n", "[g", gs.prev_hunk, "Prev hunk")
		map("n", "<leader>gg", gs.preview_hunk, "Preview hunk")
	end,
})

loader.setup("oil", {
	columns = {
		"icon",
		"permissions",
		"size",
		"mtime",
	},
	buf_options = {
		buflisted = false,
		bufhidden = "hide",
	},
	win_options = {
		wrap = false,
		signcolumn = "no",
		cursorcolumn = false,
		foldcolumn = "0",
		spell = false,
		list = false,
		conceallevel = 3,
		concealcursor = "nvic",
	},
	delete_to_trash = true,
	skip_confirm_for_simple_edits = false,
	prompt_save_on_select_new_entry = true,
	cleanup_delay_ms = 2000,
	float = {
		padding = 2,
		max_width = 90,
		max_height = 30,
		border = "rounded",
		win_options = {
			winblend = 0,
		},
	},
	preview = {
		border = "rounded",
	},
	keymaps = {
		["g?"] = "actions.show_help",
		["<CR>"] = "actions.select",
		["<C-v>"] = { "actions.select", opts = { vertical = true }, desc = "Open in vertical split" },
		["<C-x>"] = { "actions.select", opts = { horizontal = true }, desc = "Open in horizontal split" },
		["<C-t>"] = { "actions.select", opts = { tab = true }, desc = "Open in new tab" },
		["<C-p>"] = "actions.preview",
		["<C-c>"] = "actions.close",
		["<C-r>"] = "actions.refresh",
		["-"] = "actions.parent",
		["_"] = "actions.open_cwd",
		["`"] = "actions.cd",
		["~"] = { "actions.cd", opts = { scope = "tab" }, desc = "CD to current dir (tab)" },
		["gs"] = "actions.change_sort",
		["gx"] = "actions.open_external",
		["g."] = "actions.toggle_hidden",
		["g\\"] = "actions.toggle_trash",
	},
	view_options = {
		show_hidden = true,
		is_hidden_file = function(name, bufnr)
			return vim.startswith(name, ".")
		end,
		is_always_hidden = function(name, bufnr)
			return false
		end,
	},
})

loader.setup("nvim-autopairs", { check_ts = true, fast_wrap = { map = "<M-e>" } })

loader.setup("markview", {
	modes = { "n", "no" },
	hybrid_modes = { "n", "no" },
	preview = { border = "rounded" },
})

loader.setup("noice", {
	lsp = {
		progress = { enabled = false },
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
	},
	presets = { bottom_search = true, inc_rename = true },
	notify = { enabled = false, view = "mini" },
})

loader.setup("tiny-inline-diagnostic", function(tiny)
	tiny.setup({
		preset = "modern",
		options = {
			use_icons_from_diagnostic = true,
			show_source = { enabled = false, if_many = true },
			show_code = false,
			show_related = { enabled = true, max_count = 2 },
			add_messages = {
				messages = true,
				display_count = false,
				show_multiple_glyphs = true,
			},
			multilines = { enabled = false, always_show = false },
			overflow = { mode = "wrap", padding = 1 },
			throttle = 20,
			enable_on_insert = false,
		},
	})
end)
