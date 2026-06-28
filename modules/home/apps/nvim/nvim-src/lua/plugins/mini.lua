-- mini.nvim suite

local icons = require("mini.icons")
icons.setup()
icons.mock_nvim_web_devicons()

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
})

-- ═══════════════════════════════════════════════════════════════════
--  M I N I . C L U E   (which-key)
-- ═══════════════════════════════════════════════════════════════════

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
		{ mode = "n", keys = "<Leader>x", desc = "+trouble" },
		{ mode = "n", keys = "<Leader>f", desc = "+find" },
		{ mode = "n", keys = "<Leader>g", desc = "+git" },
		{ mode = "n", keys = "<Leader>l", desc = "+lsp" },
		{ mode = "n", keys = "<Leader>m", desc = "+dap" },
		{ mode = "n", keys = "<Leader>q", desc = "+quit/lists" },
		{ mode = "n", keys = "<Leader>t", desc = "+toggles/terminal" },
		{ mode = "n", keys = "<Leader>T", desc = "+tabs" },
		{ mode = "n", keys = "<Leader>w", desc = "+window" },
		{ mode = "n", keys = "<Leader>z", desc = "+zen" },
		{ mode = "n", keys = "<Leader>a", desc = "+copilot" },
		{ mode = "n", keys = "<Leader>v", desc = "+select" },
		{ mode = "n", keys = "<Leader>h", desc = "+highlights" },
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

-- ═══════════════════════════════════════════════════════════════════
--  H I G H L I G H T   P A T T E R N S
-- ═══════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════
--  O T H E R   M I N I   M O D U L E S
-- ═══════════════════════════════════════════════════════════════════

require("mini.cursorword").setup({ delay = 200 })

require("mini.indentscope").setup({
	symbol = "│",
	options = { try_as_border = true },
	draw = {
		delay = 100,
		animation = require("mini.indentscope").gen_animation.none(),
	},
})

require("mini.align").setup()
require("mini.move").setup()
require("mini.operators").setup()
require("mini.splitjoin").setup()
require("mini.trailspace").setup()
require("mini.bufremove").setup()

vim.keymap.set("n", "<leader>bd", function()
	require("mini.bufremove").delete()
end, { desc = "Delete buffer" })
