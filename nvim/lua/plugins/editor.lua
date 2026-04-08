-- Editor enhancements: file manager, git signs, formatting, pairs

-- Fyler: tree file manager
require("fyler").setup({
	integrations = {
		icon = "mini_icons",
	},
	views = {
		finder = {
			confirm_simple = false,
			delete_to_trash = true,
			default_explorer = true,
			follow_current_file = true,
			columns_order = { "link", "permission", "size", "git", "diagnostic" },
			columns = {
				permission = { enabled = true },
				size = { enabled = true },
				git = { enabled = true },
				diagnostic = { enabled = true },
				link = { enabled = true },
			},
			win = {
				kind = "split_left_most",
				border = "rounded",
				kinds = {
					split_left_most = {
						width = "30%",
						win_opts = { winfixwidth = true },
					},
				},
			},
		},
	},
})

local fyler = require("fyler")
vim.keymap.set("n", "-", function()
	fyler.toggle({ kind = "split_left_most" })
end, { desc = "Toggle Fyler" })
vim.keymap.set("n", "<leader>ef", function()
	fyler.open({ kind = "split_left_most" })
end, { desc = "Open Fyler" })

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
