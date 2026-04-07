-- =============================================================================
-- mini.nvim Suite Consolidation
-- =============================================================================
local loader = require("lib.loader")

loader.setup("mini.icons", function(icons)
	icons.setup()
	icons.mock_nvim_web_devicons()
end)

loader.setup("mini.ai", {
	custom_textobjects = {
		B = function()
			local from = { line = 1, col = 1 }
			local to = { line = vim.fn.line("$"), col = math.max(vim.fn.getline("$"):len(), 1) }
			return { from = from, to = to }
		end,
	},
})

loader.setup("mini.surround", {
	mappings = { add = "sa", delete = "sd", replace = "sr" },
	search_method = "cover_or_next",
})

loader.setup("mini.clue", function(clue)
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
		window = { delay = 250, config = { border = "rounded" } },
	})
end)

loader.setup("mini.hipatterns", function(hip)
	hip.setup({
		highlighters = {
			fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
			todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
			hex_color = hip.gen_highlighter.hex_color(),
		},
	})
end)

local modules = { "align", "move", "operators", "splitjoin", "trailspace", "cursorword", "bufremove" }
for _, m in ipairs(modules) do
	loader.setup("mini." .. m)
end

local br = loader.require("mini.bufremove")
if br then
	vim.keymap.set("n", "<leader>bd", br.delete, { desc = "Delete buffer" })
end
