-- =============================================================================
-- dial.nvim: smarter <C-a>/<C-x> (dates, hex, semver, booleans, …)
-- =============================================================================
local ok_dial, dial_map = pcall(require, "dial.map")
if not ok_dial then
	return
end

local ok_augend, augend = pcall(require, "dial.augend")
if ok_augend then
	require("dial.config").augends:register_group({
		default = {
			augend.integer.alias.decimal,
			augend.integer.alias.hex,
			augend.integer.alias.binary,
			augend.integer.alias.octal,
			augend.date.alias["%Y-%m-%d"],
			augend.date.alias["%d.%m.%Y"],
			augend.date.alias["%H:%M:%S"],
			augend.constant.alias.bool,
			augend.semver.alias.semver,
		},
	})
end

local function map(mode, lhs, direction, dial_mode, desc)
	vim.keymap.set(mode, lhs, function()
		dial_map.manipulate(direction, dial_mode)
	end, { desc = desc, silent = true })
end

map("n", "<C-a>", "increment", "normal", "Increment (dial)")
map("n", "<C-x>", "decrement", "normal", "Decrement (dial)")
map("n", "g<C-a>", "increment", "gnormal", "Increment sequential (dial)")
map("n", "g<C-x>", "decrement", "gnormal", "Decrement sequential (dial)")
map("x", "<C-a>", "increment", "visual", "Increment selection (dial)")
map("x", "<C-x>", "decrement", "visual", "Decrement selection (dial)")
map("x", "g<C-a>", "increment", "gvisual", "Increment selection sequential (dial)")
map("x", "g<C-x>", "decrement", "gvisual", "Decrement selection sequential (dial)")
