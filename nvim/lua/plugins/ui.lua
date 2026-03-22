-- =============================================================================
-- UI Plugins Configuration
-- =============================================================================
-- Visual enhancements: gitsigns, oil, autopairs, markview, noice.
--
-- Gitsigns is the sole git-hunk provider. mini.diff has been removed to
-- avoid duplicate sign-column decorations and summary components.
-- All hunk keymaps are attached per-buffer inside on_attach so they are
-- only active where a git buffer exists.
-- =============================================================================

local loader = require("lib.loader")

-- ── gitsigns (git integration) ────────────────────────────────────────────
loader.setup("gitsigns", function(gitsigns)
	gitsigns.setup({
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "" },
			topdelete = { text = "" },
			changedelete = { text = "▎" },
			untracked = { text = "▎" },
		},
		-- Blame is off by default; toggled with <leader>tb
		current_line_blame = false,
		current_line_blame_opts = {
			delay = 500,
			virt_text_pos = "eol",
		},
		preview_config = { border = "rounded" },
		signcolumn = true,

		on_attach = function(bufnr)
			local gs = gitsigns
			local map = function(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
			end

			-- ── Hunk navigation ──────────────────────────────────────────
			map("n", "]g", function()
				if vim.wo.diff then
					vim.cmd.normal({ "]c", bang = true })
				else
					gs.nav_hunk("next")
				end
			end, "Next hunk")
			map("n", "[g", function()
				if vim.wo.diff then
					vim.cmd.normal({ "[c", bang = true })
				else
					gs.nav_hunk("prev")
				end
			end, "Prev hunk")

			-- ── Hunk actions ─────────────────────────────────────────────
			map("n", "<leader>gg", gs.preview_hunk, "Preview hunk")
			map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
			map("n", "<leader>gu", gs.undo_stage_hunk, "Undo stage hunk")
			map("n", "<leader>gR", gs.reset_hunk, "Reset hunk")
			map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
			map("n", "<leader>gb", gs.blame_line, "Blame line")
			map("n", "<leader>gd", gs.diffthis, "Diff this")
			map("n", "<leader>gD", function()
				gs.diffthis("~")
			end, "Diff against last commit")

			-- ── Visual-mode hunk stage/reset ─────────────────────────────
			map("v", "<leader>gs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Stage hunk (range)")
			map("v", "<leader>gR", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, "Reset hunk (range)")

			-- ── Text object: ih = inner hunk ─────────────────────────────
			map({ "o", "x" }, "ih", ":<C-u>Gitsigns select_hunk<CR>", "Select hunk")

			-- ── Toggle blame (per-buffer) ─────────────────────────────────
			map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle line blame")
		end,
	})
end)

-- ── Oil (file navigation) ─────────────────────────────────────────────────
loader.setup("oil", function(oil)
	oil.setup({
		view_options = {
			show_hidden = true,
			is_always_hidden = function(name, _)
				return name == ".git"
			end,
		},
		float = { border = "rounded" },
		keymaps = {
			-- Unset defaults that conflict with window navigation
			["<C-s>"] = false,
			["<C-h>"] = false,
			["<C-v>"] = { "actions.select", opts = { vertical = true } },
			["<C-x>"] = { "actions.select", opts = { horizontal = true } },
		},
		win_options = {
			cursorline = false,
		},
	})
end)

-- ── nvim-autopairs ────────────────────────────────────────────────────────
loader.setup("nvim-autopairs", function(autopairs)
	autopairs.setup({
		check_ts = true,
		ts_config = { lua = { "string" }, javascript = { "template_string" } },
		fast_wrap = { map = "<M-e>" },
		completion = true,
	})
end)

-- ── markview (markdown preview) ───────────────────────────────────────────
loader.setup("markview", function(markview)
	markview.setup({
		-- "n" and "no" only — command mode ("c") causes flicker when entering
		-- ex-commands in markdown buffers and serves no real purpose here
		modes = { "n", "no" },
		hybrid_modes = { "n", "no" },
	})
end)

-- ── noice (cmdline & notifications) ───────────────────────────────────────
loader.setup("noice", function(noice)
	noice.setup({
		-- Route noice notifications through the mini view so vim.notify
		-- output (including loader errors) renders consistently
		notify = { enabled = false, view = "mini" },
		messages = {
			enabled = false,
			view = "mini",
		},
		lsp = {
			progress = { enabled = false },
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
			},
			hover = { enabled = false },
			signature = { enabled = false },
		},
		cmdline = {
			enabled = true,
			view = "cmdline",
			format = {
				cmdline = { pattern = "^:", icon = ">", lang = "vim" },
				search_down = { pattern = "^/", icon = "?", lang = "regex" },
				search_up = { pattern = "^?", icon = "?", lang = "regex" },
				filter = { pattern = "^:%s*!", icon = "", lang = "bash" },
				lua = { pattern = "^:%s*lua%s+", icon = "", lang = "lua" },
				help = { pattern = "^:%s*he?l?p?%s+", icon = "󰋖" },
				input = { view = "cmdline_input", icon = "󰥻 " },
			},
		},
		inc_rename = { enabled = true },
		presets = {
			bottom_search = true,
			command_palette = false,
			long_message_to_split = true,
			inc_rename = true,
			lsp_doc_border = true,
		},
		routes = {
			-- Send common write/undo noise to the mini view instead of a
			-- full popup
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
end)
