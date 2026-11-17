-- Mini.nvim modules that need no per-plugin file.

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

-- mini.clue (which-key) is intentionally not enabled: the key popup is not
-- wanted. Re-enable it here and restore keymaps/groups.lua to bring it back.

local hipatterns = require("mini.hipatterns")
hipatterns.setup({
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		hex_color = hipatterns.gen_highlighter.hex_color(),
	},
})

require("mini.cursorword").setup({ delay = 200 })
require("mini.align").setup()
require("mini.move").setup()
require("mini.operators").setup({ replace = { prefix = "gR" } })
require("mini.splitjoin").setup()
require("mini.trailspace").setup()
require("mini.pairs").setup()
require("mini.bufremove").setup({})

-- Empty suffixes disable the targets that already have bespoke mappings:
-- treesitter function/class jumps, diagnostics with floats, and the rest.
require("mini.bracketed").setup({
	buffer = { suffix = "" },
	comment = { suffix = "" },
	diagnostic = { suffix = "" },
	file = { suffix = "" },
	location = { suffix = "" },
	quickfix = { suffix = "" },
	treesitter = { suffix = "" },
})
