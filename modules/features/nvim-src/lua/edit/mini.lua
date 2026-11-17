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

-- mini.clue (which-key). Leader groups come from keymaps/groups.lua so the
-- menu and the actual mappings cannot drift apart.
local clue = require("mini.clue")
local clues = {
	clue.gen_clues.builtin_completion(),
	clue.gen_clues.g(),
	clue.gen_clues.marks(),
	clue.gen_clues.registers(),
	clue.gen_clues.windows(),
	clue.gen_clues.z(),
}
for _, group in ipairs(require("keymaps.groups")) do
	clues[#clues + 1] = { mode = "n", keys = group.keys, desc = group.desc }
end
for _, entry in ipairs({
	{ mode = { "n", "x" }, keys = "s", desc = "+surround" },
	{ mode = { "n", "x" }, keys = "sa", desc = "Add surrounding" },
	{ mode = { "n", "x" }, keys = "sd", desc = "Delete surrounding" },
	{ mode = { "n", "x" }, keys = "sr", desc = "Replace surrounding" },
	{ mode = { "n", "x" }, keys = "sf", desc = "Find surrounding" },
	{ mode = "n", keys = "sF", desc = "Find surrounding left" },
	{ mode = { "n", "x" }, keys = "sh", desc = "Highlight surrounding" },
	{ mode = "n", keys = "sn", desc = "Update n lines" },
}) do
	clues[#clues + 1] = entry
end
clue.setup({
	clues = clues,
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
