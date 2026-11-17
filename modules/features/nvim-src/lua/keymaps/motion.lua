-- Motions: flash, treesitter textobjects, and dial increments.

local map = vim.keymap.set
local flash_ui = require("ui.flash")
local treesitter = require("edit.treesitter")
local dial_map = require("ui.dial")

-- Flash
map({ "n", "x", "o" }, "<leader><leader>", function()
	if flash_ui.is_main_editor() then
		flash_ui.flash.jump()
	end
end, { desc = "Flash jump" })
map({ "n", "x", "o" }, "S", function()
	if flash_ui.is_main_editor() then
		flash_ui.flash.treesitter()
	end
end, { desc = "Flash treesitter" })

-- Treesitter textobjects
local textobjects = {
	["af"] = { query = "@function.outer", desc = "Around function" },
	["if"] = { query = "@function.inner", desc = "Inside function" },
	["ac"] = { query = "@class.outer", desc = "Around class" },
	["ic"] = { query = "@class.inner", desc = "Inside class" },
	["aa"] = { query = "@parameter.outer", desc = "Around parameter" },
	["ia"] = { query = "@parameter.inner", desc = "Inside parameter" },
}
for key, spec in pairs(textobjects) do
	map({ "o", "x" }, key, function()
		treesitter.select.select_textobject(spec.query)
	end, { silent = true, desc = spec.desc })
end

-- Function and class movement
local movements = {
	{ "]f", "goto_next_start", "@function.outer", "Next function" },
	{ "[f", "goto_previous_start", "@function.outer", "Previous function" },
	{ "]c", "goto_next_start", "@class.outer", "Next class" },
	{ "[c", "goto_previous_start", "@class.outer", "Previous class" },
}
for _, movement in ipairs(movements) do
	map({ "n", "o", "x" }, movement[1], function()
		treesitter.move[movement[2]](movement[3])
	end, { silent = true, desc = movement[4] })
end

-- Dial
local function dial(mode, lhs, direction, dial_mode, desc)
	map(mode, lhs, function()
		dial_map.manipulate(direction, dial_mode)
	end, { desc = desc, silent = true })
end
dial("n", "<C-a>", "increment", "normal", "Increment (dial)")
dial("n", "<C-x>", "decrement", "normal", "Decrement (dial)")
dial("n", "g<C-a>", "increment", "gnormal", "Increment sequential (dial)")
dial("n", "g<C-x>", "decrement", "gnormal", "Decrement sequential (dial)")
dial("x", "<C-a>", "increment", "visual", "Increment selection (dial)")
dial("x", "<C-x>", "decrement", "visual", "Decrement selection (dial)")
dial("x", "g<C-a>", "increment", "gvisual", "Increment selection sequential (dial)")
dial("x", "g<C-x>", "decrement", "gvisual", "Decrement selection sequential (dial)")
