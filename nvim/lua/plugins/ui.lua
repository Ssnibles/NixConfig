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
	float = { border = "rounded" },
	view_options = { show_hidden = true },
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
