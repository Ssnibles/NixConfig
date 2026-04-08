-- Editor enhancements: file manager, git signs, formatting, pairs

-- Oil: file manager as buffer
require("oil").setup({
	columns = { "icon", "permissions", "size", "mtime" },
	delete_to_trash = true,
	skip_confirm_for_simple_edits = true,
	view_options = { show_hidden = true },
	float = { padding = 2, max_width = 90, max_height = 30, border = "rounded" },
	keymaps = {
		["g?"] = "actions.show_help",
		["<CR>"] = "actions.select",
		["<C-v>"] = { "actions.select", opts = { vertical = true } },
		["<C-x>"] = { "actions.select", opts = { horizontal = true } },
		["<C-p>"] = "actions.preview",
		["<C-c>"] = "actions.close",
		["-"] = "actions.parent",
		["g."] = "actions.toggle_hidden",
	},
})

-- Gitsigns: git integration in gutter
require("gitsigns").setup({
	signs = {
		add = { text = "▎" },
		change = { text = "▎" },
		delete = { text = " " },
		topdelete = { text = " " },
		changedelete = { text = "▎" },
	},
	preview_config = { border = "rounded" },
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local map = function(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
		end
		map("n", "]g", gs.next_hunk, "Next hunk")
		map("n", "[g", gs.prev_hunk, "Prev hunk")
		map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
		map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
		map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
		map("n", "<leader>gb", gs.blame_line, "Blame line")
	end,
})

-- Conform: formatting
require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettier" },
		typescript = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		nix = { "nixfmt" },
		sh = { "shfmt" },
		kotlin = { "ktlint" },
		java = { "google-java-format" },
		cs = { "csharpier" },
	},
	format_on_save = function(bufnr)
		local disabled = { c = true, cpp = true }
		local ft = vim.bo[bufnr].filetype
		if disabled[ft] then
			return nil
		end
		return { timeout_ms = 1000, lsp_format = "fallback" }
	end,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

-- Autopairs
require("nvim-autopairs").setup({ check_ts = true, fast_wrap = { map = "<M-e>" } })
