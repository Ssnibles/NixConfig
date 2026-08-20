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
		{ mode = "n", keys = "<Leader>q", desc = "+quit/lists" },
		{ mode = "n", keys = "<Leader>s", desc = "+starter/session" },
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

require("mini.cursorword").setup({ delay = 200 })

require("mini.align").setup()
require("mini.move").setup()
require("mini.operators").setup()
require("mini.splitjoin").setup()

require("mini.pairs").setup()
require("mini.bufremove").setup({})
require("mini.sessions").setup({
	autoread = true,
	autowrite = true,
	hooks = {
		post_autowrite = function() end,
	},
})

local starter = require("mini.starter")
local logo = [[
  ⠀⠀⠀⠀⠀⠀⡠⠛⠋⠉⠉⠓⠻⢤⠀
  ⠀⠀⠀⠀⠀⡟⣠⣶⠖⣤⠀⣴⣯⣹⣷
  ⠀⣀⣀⣀⠀⣆⢹⣿⣿⡿⠀⠹⠿⠿⣉
  ⡞⠀⠀⠀⠀⠀⠓⠦⢄⡄⠩⠥⠔⠊⠁
  ⠙⡄⢠⣴⣶⣦⠀⢠⡄⣴⠀⣯⠀⠀⠀
  ⠀⠲⠖⠁⠉⠁⠧⠼⠁⠈⠓⠋⠀⠀⠀
]]

starter.setup({
	header = logo,
	items = {
		{
			name = "New file",
			action = "enew",
			section = "Actions",
		},
		{
			name = "Open oldfile (fzf)",
			action = function()
				require("fzf-lua").oldfiles()
			end,
			section = "Actions",
		},
		{
			name = "Open Neovim Wiki",
			action = "help nvim",
			section = "Actions",
		},
		{
			name = "Quit Neovim",
			action = "qa",
			section = "Actions",
		},
	},
	content_hooks = {
		starter.gen_hook.adding_bullet("  󰅂 ", false),
		starter.gen_hook.indexing("section", { "Actions" }),
		starter.gen_hook.aligning("center", "center"),
	},
	footer = "",
})
