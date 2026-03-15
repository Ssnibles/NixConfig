-- ── mini.nvim ─────────────────────────────────────────────────────────────
-- Single entry-point for the entire mini.nvim suite.
--
-- vim.schedule defers setup until after Nix has finished populating the
-- runtimepath, so all mini.* submodules are resolvable by the time we
-- call require().

vim.schedule(function()
	-- ── Text objects ──────────────────────────────────────────────────────────
	require("mini.ai").setup({
		custom_textobjects = {
			-- 'B' = whole buffer (e.g. vaB, daB, yiB)
			B = function()
				local from = { line = 1, col = 1 }
				local to = { line = vim.fn.line("$"), col = math.max(vim.fn.getline("$"):len(), 1) }
				return { from = from, to = to }
			end,
		},
	})

	-- ── Surround ──────────────────────────────────────────────────────────────
	require("mini.surround").setup({
		mappings = {
			add = "sa",
			delete = "sd",
			replace = "sr",
			find = "sf",
			find_left = "sF",
			highlight = "sh",
			update_n_lines = "sn",
		},
		search_method = "cover_or_next",
	})

	-- ── Align ─────────────────────────────────────────────────────────────────
	require("mini.align").setup({
		mappings = { start = "ga", start_with_preview = "gA" },
	})

	-- ── Move lines / selections ───────────────────────────────────────────────
	require("mini.move").setup({
		mappings = {
			left = "<M-h>",
			right = "<M-l>",
			down = "<M-j>",
			up = "<M-k>",
			line_left = "<M-h>",
			line_right = "<M-l>",
			line_down = "<M-j>",
			line_up = "<M-k>",
		},
	})

	-- ── Operators ─────────────────────────────────────────────────────────────
	-- gx = exchange, gm = multiply/duplicate, g= = evaluate, gR = replace with reg, gs = sort
	require("mini.operators").setup({
		evaluate = { prefix = "g=" },
		exchange = { prefix = "gx" },
		multiply = { prefix = "gm" },
		replace = { prefix = "gR" },
		sort = { prefix = "gs" },
	})

	-- ── Split / join ──────────────────────────────────────────────────────────
	-- gS toggles function args / tables between single-line ↔ multi-line
	require("mini.splitjoin").setup({ mappings = { toggle = "gS" } })

	-- ── Trailspace ────────────────────────────────────────────────────────────
	-- Highlights trailing whitespace. trim() is called from autocommands.lua.
	require("mini.trailspace").setup()

	-- ── Cursorword ────────────────────────────────────────────────────────────
	require("mini.cursorword").setup()

	-- ── Comment ───────────────────────────────────────────────────────────────
	require("mini.comment").setup()

	-- ── Bufremove ─────────────────────────────────────────────────────────────
	-- Smarter :bdelete — preserves window layout.
	local bufremove = require("mini.bufremove")
	bufremove.setup()
	vim.keymap.set("n", "<leader>bd", function()
		bufremove.delete()
	end, { desc = "Delete buffer (keep layout)" })
	vim.keymap.set("n", "<leader>bD", function()
		bufremove.delete(0, true)
	end, { desc = "Force-delete buffer" })

	-- ── Jump2d ────────────────────────────────────────────────────────────────
	-- <leader><leader> then type the two-char label to hop anywhere on screen.
	require("mini.jump2d").setup({
		mappings = { start_jumping = "<leader><leader>" },
		view = { dim = true, n_steps_ahead = 2 },
	})

	-- ── Diff ──────────────────────────────────────────────────────────────────
	-- Better diff algorithm with sign-column hunks (mirrors gitsigns style).
	require("mini.diff").setup({
		view = {
			style = "sign",
			signs = { add = "▎", change = "▎", delete = "" },
		},
	})

	-- ── Extra ─────────────────────────────────────────────────────────────────
	-- Provides treesitter helpers used by mini.ai and mini.clue.
	require("mini.extra").setup()

	-- ── Starter (dashboard) ───────────────────────────────────────────────────
	-- autoopen = false; open manually with :lua MiniStarter.open() if needed.
	require("mini.starter").setup({ autoopen = false })

	-- ── Icons ─────────────────────────────────────────────────────────────────
	require("mini.icons").setup({
		style = "glyph",
		use_file_extension = function(ext, _)
			return not ({ ["min"] = true, ["map"] = true })[ext]
		end,
	})

	-- ── Clue (keybinding hints) ───────────────────────────────────────────────
	local clue = require("mini.clue")
	clue.setup({
		clues = {
			clue.gen_clues.builtin_completion(),
			clue.gen_clues.g(),
			clue.gen_clues.marks(),
			clue.gen_clues.registers(),
			clue.gen_clues.windows(),
			clue.gen_clues.z(),

			-- Leader groups (mirror keymaps.lua)
			{ mode = "n", keys = "<Leader>", desc = "+leader" },
			{ mode = "x", keys = "<Leader>", desc = "+leader" },
			{ mode = "n", keys = "<Leader>b", desc = "+buffer" },
			{ mode = "n", keys = "<Leader>c", desc = "+code" },
			{ mode = "n", keys = "<Leader>d", desc = "+diagnostics" },
			{ mode = "n", keys = "<Leader>f", desc = "+find" },
			{ mode = "n", keys = "<Leader>g", desc = "+git" },
			{ mode = "n", keys = "<Leader>l", desc = "+lsp" },
			{ mode = "n", keys = "<Leader>q", desc = "+quickfix" },
			{ mode = "n", keys = "<Leader>t", desc = "+toggle" },
			{ mode = "n", keys = "<Leader>w", desc = "+window" },
			-- mini.surround
			{ mode = "n", keys = "s", desc = "+surround" },
			{ mode = "n", keys = "sa", desc = "Surround add" },
			{ mode = "n", keys = "sd", desc = "Surround delete" },
			{ mode = "n", keys = "sr", desc = "Surround replace" },
			{ mode = "n", keys = "sf", desc = "Surround find →" },
			{ mode = "n", keys = "sF", desc = "Surround find ←" },
			{ mode = "n", keys = "sh", desc = "Surround highlight" },
			-- mini.align
			{ mode = "n", keys = "ga", desc = "Align" },
			{ mode = "n", keys = "gA", desc = "Align (preview)" },
			-- mini.operators
			{ mode = "n", keys = "g=", desc = "Evaluate" },
			{ mode = "n", keys = "gx", desc = "Exchange" },
			{ mode = "n", keys = "gm", desc = "Multiply" },
			{ mode = "n", keys = "gR", desc = "Replace w/ reg" },
			{ mode = "n", keys = "gs", desc = "Sort" },
			{ mode = "n", keys = "gS", desc = "Split/join toggle" },
			-- navigation
			{ mode = "n", keys = "]", desc = "+next" },
			{ mode = "n", keys = "[", desc = "+prev" },
		},

		triggers = {
			{ mode = "n", keys = "<Leader>" },
			{ mode = "x", keys = "<Leader>" },
			{ mode = "n", keys = "g" },
			{ mode = "n", keys = "z" },
			{ mode = "n", keys = "<C-w>" },
			{ mode = "n", keys = "]" },
			{ mode = "n", keys = "[" },
			{ mode = "n", keys = "s" },
			{ mode = "n", keys = "'" },
			{ mode = "n", keys = "`" },
			{ mode = "n", keys = '"' },
		},

		window = {
			delay = 250,
			config = { border = "rounded", width = "auto" },
		},
	})

	-- ── Hipatterns ────────────────────────────────────────────────────────────
	local hip = require("mini.hipatterns")
	hip.setup({
		highlighters = {
			fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
			fixit = { pattern = "%f[%w]()FIXIT()%f[%W]", group = "MiniHipatternsFixme" },
			error = { pattern = "%f[%w]()ERROR()%f[%W]", group = "MiniHipatternsFixme" },
			warn = { pattern = "%f[%w]()WARN()%f[%W]", group = "MiniHipatternsFixme" },
			hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
			bug = { pattern = "%f[%w]()BUG()%f[%W]", group = "MiniHipatternsHack" },
			todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
			note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
			info = { pattern = "%f[%w]()INFO()%f[%W]", group = "MiniHipatternsNote" },
			hint = { pattern = "%f[%w]()HINT()%f[%W]", group = "MiniHipatternsNote" },
			hex_color = hip.gen_highlighter.hex_color(),
		},
	})
end)
