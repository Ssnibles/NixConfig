-- ── Mini.icons ───────────────────────────────────────────────────────
local icons = require("mini.icons")
icons.setup()
icons.mock_nvim_web_devicons()

-- ── Mini.ai (textobjects) ────────────────────────────────────────────
require("mini.ai").setup({
	n_lines = 500,
	custom_textobjects = {
		B = function()
			return {
				from = { line = 1, col = 1 },
				to = { line = vim.fn.line("$"), col = math.max(vim.fn.getline("$"):len(), 1) },
			}
		end,
	},
})

-- ── Mini.surround ────────────────────────────────────────────────────
require("mini.surround").setup({
	mappings = {
		add = "sa", delete = "sd", replace = "sr", find = "sf",
		find_left = "sF", highlight = "sh", update_n_lines = "sn",
	},
})

-- Typst: `san` wraps a range/selection in `#noln[…]` (no line numbers) and
-- `sal` wraps it in `#ln[…]`. Scoped to Typst buffers via the buffer-local
-- config mini.surround merges on top of the global one.
vim.api.nvim_create_autocmd("FileType", {
	pattern = "typst",
	callback = function(args)
		vim.b[args.buf].minisurround_config = {
			custom_surroundings = {
				n = { output = { left = "#noln[", right = "]" } },
				l = { output = { left = "#ln[", right = "]" } },
			},
		}
	end,
	desc = "Typst line-number surrounds (#noln / #ln)",
})

-- ── Mini.clue (which-key) ────────────────────────────────────────────
local clue = require("mini.clue")
clue.setup({
	clues = {
		clue.gen_clues.builtin_completion(),
		clue.gen_clues.g(),
		clue.gen_clues.marks(),
		clue.gen_clues.registers(),
		clue.gen_clues.windows(),
		clue.gen_clues.z(),
		{ mode = "n", keys = "<Leader>b", desc = "+buffers" },
		{ mode = "n", keys = "<Leader>c", desc = "+code" },
		{ mode = "n", keys = "<Leader>d", desc = "+diagnostics" },
		{ mode = "n", keys = "<Leader>f", desc = "+find" },
		{ mode = "n", keys = "<Leader>g", desc = "+git" },
		{ mode = "n", keys = "<Leader>l", desc = "+lsp" },
		{ mode = "n", keys = "<Leader>m", desc = "+dap" },
		{ mode = "n", keys = "<Leader>r", desc = "+refactor/rename" },
		{ mode = "n", keys = "<Leader>q", desc = "+quit/lists" },
		{ mode = "n", keys = "<Leader>t", desc = "+toggles/terminal" },
		{ mode = "n", keys = "<Leader>T", desc = "+tabs" },
		{ mode = "n", keys = "<Leader>w", desc = "+window" },
		{ mode = "n", keys = "<Leader>a", desc = "+copilot" },
		{ mode = "n", keys = "<Leader>x", desc = "+lists" },
		{ mode = "n", keys = "<Leader>v", desc = "+select" },
	},
	triggers = {
		{ mode = "n", keys = "<Leader>" },
		{ mode = "x", keys = "<Leader>" },
		{ mode = "n", keys = "g" },
		{ mode = "n", keys = "z" },
		{ mode = "n", keys = "<C-w>" },
		{ mode = "n", keys = "s" },
	},
	window = { delay = 300, config = { border = "rounded", width = "auto" } },
})

-- ── Mini.hipatterns ──────────────────────────────────────────────────
local hip = require("mini.hipatterns")
hip.setup({
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		hex_color = hip.gen_highlighter.hex_color(),
	},
})

-- ── Simple mini modules ──────────────────────────────────────────────
require("mini.cursorword").setup({ delay = 200 })
require("mini.align").setup()
require("mini.move").setup()
require("mini.operators").setup({ replace = { prefix = "gR" } })
require("mini.splitjoin").setup()
require("mini.trailspace").setup()
require("mini.pairs").setup()
require("mini.bufremove").setup({})

-- ── Mini.bracketed (extra `[`/`]` motions) ───────────────────────────
-- Disable targets that already have bespoke mappings (treesitter class/
-- function jumps, diagnostics with floats, etc.) to avoid clobbering them.
require("mini.bracketed").setup({
	comment = { suffix = "" },
	diagnostic = { suffix = "" },
	file = { suffix = "" },
	location = { suffix = "" },
	quickfix = { suffix = "" },
	treesitter = { suffix = "" },
})
