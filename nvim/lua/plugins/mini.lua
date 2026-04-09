-- mini.nvim suite

local c = require("theme").colors

-- Icons (with nvim-web-devicons compatibility)
local icons = require("mini.icons")
icons.setup()
icons.mock_nvim_web_devicons()

-- Text objects
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

-- Surround
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

-- Key hints (which-key alternative)
local clue = require("mini.clue")
clue.setup({
	clues = {
		clue.gen_clues.builtin_completion(),
		clue.gen_clues.g(),
		clue.gen_clues.marks(),
		clue.gen_clues.registers(),
		clue.gen_clues.windows(),
		clue.gen_clues.z(),
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

-- Highlight patterns (TODO, FIXME, etc.)
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

-- Cursor word highlight
require("mini.cursorword").setup({ delay = 200 })

-- Indent scope
require("mini.indentscope").setup({
	symbol = "│",
	options = { try_as_border = true },
	draw = {
		delay = 100,
		animation = require("mini.indentscope").gen_animation.none(),
	},
})
vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = c.blue, nocombine = true })

-- Additional mini modules
require("mini.align").setup()
require("mini.move").setup()
require("mini.operators").setup()
require("mini.splitjoin").setup()
require("mini.trailspace").setup()
require("mini.bufremove").setup()

-- Buffer delete keymap
vim.keymap.set("n", "<leader>bd", function()
	require("mini.bufremove").delete()
end, { desc = "Delete buffer" })
