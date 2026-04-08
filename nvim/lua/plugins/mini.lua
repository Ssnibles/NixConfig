-- =============================================================================
-- mini.nvim Suite Consolidation
-- =============================================================================
-- Collection of focused, well-designed mini modules for enhanced editing
-- =============================================================================
local loader = require("lib.loader")

-- ── Icons ────────────────────────────────────────────────────────────────────
loader.setup("mini.icons", function(icons)
	icons.setup()
	icons.mock_nvim_web_devicons()
end)

-- ── Text Objects ─────────────────────────────────────────────────────────────
loader.setup("mini.ai", {
	n_lines = 500, -- Search up to 500 lines for text objects
	custom_textobjects = {
		-- 'B' for entire buffer text object
		B = function()
			local from = { line = 1, col = 1 }
			local to = { line = vim.fn.line("$"), col = math.max(vim.fn.getline("$"):len(), 1) }
			return { from = from, to = to }
		end,
	},
})

-- ── Surround ─────────────────────────────────────────────────────────────────
loader.setup("mini.surround", {
	mappings = {
		add = "sa",            -- Add surrounding: sa + textobj + char
		delete = "sd",         -- Delete surrounding: sd + char
		replace = "sr",        -- Replace surrounding: sr + oldchar + newchar
		find = "sf",           -- Find surrounding (next)
		find_left = "sF",      -- Find surrounding (prev)
		highlight = "sh",      -- Highlight surrounding
		update_n_lines = "sn", -- Update search lines
	},
	search_method = "cover_or_next",
})

-- ── Key Clue (Which-key alternative) ─────────────────────────────────────────
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
		window = {
			delay = 300,
			config = {
				border = "rounded",
				width = "auto",
			},
		},
	})
end)

-- ── Highlight Patterns ───────────────────────────────────────────────────────
loader.setup("mini.hipatterns", function(hip)
	hip.setup({
		highlighters = {
			fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
			todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
			note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
			hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
			hex_color = hip.gen_highlighter.hex_color(),
		},
	})
end)

-- ── Cursor Word ──────────────────────────────────────────────────────────────
loader.setup("mini.cursorword", {
	delay = 200, -- Delay before highlighting (ms)
})

-- ── Additional Mini Modules ──────────────────────────────────────────────────
local modules = { "align", "move", "operators", "splitjoin", "trailspace", "bufremove" }
for _, m in ipairs(modules) do
	loader.setup("mini." .. m)
end

-- ── Buffer Management Keymap ─────────────────────────────────────────────────
local br = loader.require("mini.bufremove")
if br then
	vim.keymap.set("n", "<leader>bd", br.delete, { desc = "Delete buffer" })
	vim.keymap.set("n", "<leader>bD", function()
		br.delete(0, true)
	end, { desc = "Delete buffer (force)" })
end
