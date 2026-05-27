-- Editor enhancements: file manager, git signs, formatting, pairs

-- Oil: file manager
require("oil").setup({
	default_file_explorer = true,
	delete_to_trash = true,
	columns = {
		"icon",
		"permissions",
		"size",
	},
	view_options = {
		is_hidden_file = function(name, _)
			return name ~= ".." and name:match("^%.") ~= nil
		end,
	},
	float = {
		border = "rounded",
		max_width = 0.8,
		max_height = 0.8,
	},
})

vim.keymap.set("n", "<leader>fe", function()
	require("oil").open_float()
end, { desc = "Explorer (Oil)" })

-- Gitsigns: git integration with line highlights instead of gutter signs
require("gitsigns").setup({
	signcolumn = false,
	linehl = true,
	numhl = false,
	word_diff = false,
	preview_config = { border = "rounded" },
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local map = function(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
		end
		map("n", "]g", gs.next_hunk, "Next hunk")
		map("n", "[g", gs.prev_hunk, "Prev hunk")
		map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
		map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
		map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
		map("n", "<leader>gb", gs.blame_line, "Blame line")
		map("n", "<leader>gd", gs.diffthis, "Diff this")
	end,
})

-- Derive git sign line backgrounds from theme (works with light & dark).
local c = require("theme").colors
local function blend_hex(fg, bg, alpha)
	local function parse(hex)
		hex = hex:gsub("#", "")
		return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	end
	local r1, g1, b1 = parse(fg)
	local r2, g2, b2 = parse(bg)
	local r = math.floor(r1 * alpha + r2 * (1 - alpha) + 0.5)
	local g = math.floor(g1 * alpha + g2 * (1 - alpha) + 0.5)
	local b = math.floor(b1 * alpha + b2 * (1 - alpha) + 0.5)
	return string.format("#%02x%02x%02x", r, g, b)
end
local git_bg = {
	add = blend_hex(c.green, c.bg, 0.12),
	delete = blend_hex(c.red, c.bg, 0.12),
	change = blend_hex(c.yellow, c.bg, 0.12),
}

for _, staged in ipairs({ "", "Staged" }) do
	for _, kind in ipairs({ "Ln", "Cul" }) do
		for ty, bg in pairs(git_bg) do
			local hl = ("GitSigns%s%s%s"):format(staged, ty:gsub("^%l", string.upper), kind)
			vim.api.nvim_set_hl(0, hl, { bg = bg })
		end
	end
end

-- Conform: formatting
vim.g.disable_autoformat = vim.g.disable_autoformat or false
vim.g.disable_autoformat_ft = vim.g.disable_autoformat_ft or { c = true, cpp = true }

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettier" },
		javascriptreact = { "prettier" },
		typescript = { "prettier" },
		typescriptreact = { "prettier" },
		css = { "prettier" },
		json = { "prettier" },
		yaml = { "prettier" },
		markdown = { "prettier" },
		nix = { "nixfmt" },
		sh = { "shfmt" },
		kotlin = { "ktlint" },
		java = { "google-java-format" },
		cs = { "csharpier" },
		typst = { "typstyle" },
	},
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat then
			return nil
		end
		local ft = vim.bo[bufnr].filetype
		if vim.g.disable_autoformat_ft[ft] then
			return nil
		end
		return { timeout_ms = 1000, lsp_format = "fallback" }
	end,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>tf", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	local msg = vim.g.disable_autoformat and "disabled" or "enabled"
	vim.notify(("Autoformat %s"):format(msg), vim.log.levels.INFO)
end, { desc = "Toggle autoformat" })

vim.keymap.set("n", "<leader>tF", function()
	local ft = vim.bo.filetype
	if ft == "" then
		return
	end
	vim.g.disable_autoformat_ft[ft] = not vim.g.disable_autoformat_ft[ft]
	local msg = vim.g.disable_autoformat_ft[ft] and "disabled" or "enabled"
	vim.notify(("Autoformat for %s %s"):format(ft, msg), vim.log.levels.INFO)
end, { desc = "Toggle autoformat for filetype" })

-- Dial: enhanced increment/decrement
local augend = require("dial.augend")
require("dial.config").augends:register_group({
	default = {
		augend.integer.alias.decimal,
		augend.integer.alias.hex,
		augend.date.alias["%Y/%m/%d"],
		augend.date.alias["%Y-%m-%d"],
		augend.constant.alias.bool,
		augend.constant.alias.alpha,
		augend.constant.alias.Alpha,
	},
})

local dial_map = require("dial.map")
vim.keymap.set("n", "<C-a>", dial_map.inc_normal(), { desc = "Increment" })
vim.keymap.set("n", "<C-x>", dial_map.dec_normal(), { desc = "Decrement" })
vim.keymap.set("v", "<C-a>", dial_map.inc_visual(), { desc = "Increment selection" })
vim.keymap.set("v", "<C-x>", dial_map.dec_visual(), { desc = "Decrement selection" })
vim.keymap.set("n", "g<C-a>", dial_map.inc_gnormal(), { desc = "Increment (g)" })
vim.keymap.set("n", "g<C-x>", dial_map.dec_gnormal(), { desc = "Decrement (g)" })
vim.keymap.set("v", "g<C-a>", dial_map.inc_gvisual(), { desc = "Increment selection (g)" })
vim.keymap.set("v", "g<C-x>", dial_map.dec_gvisual(), { desc = "Decrement selection (g)" })

-- Multicursor (default-style mappings)
local mc = require("multicursor-nvim")
mc.setup()

vim.keymap.set({ "n", "x" }, "<Up>", function()
	mc.lineAddCursor(-1)
end, { desc = "Multicursor add above" })
vim.keymap.set({ "n", "x" }, "<Down>", function()
	mc.lineAddCursor(1)
end, { desc = "Multicursor add below" })
vim.keymap.set({ "n", "x" }, "<leader><Up>", function()
	mc.lineSkipCursor(-1)
end, { desc = "Multicursor skip above" })
vim.keymap.set({ "n", "x" }, "<leader><Down>", function()
	mc.lineSkipCursor(1)
end, { desc = "Multicursor skip below" })

vim.keymap.set({ "n", "x" }, "<leader>n", function()
	mc.matchAddCursor(1)
end, { desc = "Multicursor add next match" })
vim.keymap.set({ "n", "x" }, "<leader>s", function()
	mc.matchSkipCursor(1)
end, { desc = "Multicursor skip next match" })
vim.keymap.set({ "n", "x" }, "<leader>N", function()
	mc.matchAddCursor(-1)
end, { desc = "Multicursor add prev match" })
vim.keymap.set({ "n", "x" }, "<leader>S", function()
	mc.matchSkipCursor(-1)
end, { desc = "Multicursor skip prev match" })

vim.keymap.set({ "n", "x" }, "<C-q>", mc.toggleCursor, { desc = "Multicursor toggle at cursor" })
vim.keymap.set("n", "<C-LeftMouse>", mc.handleMouse, { desc = "Multicursor mouse toggle" })
vim.keymap.set("n", "<C-LeftDrag>", mc.handleMouseDrag)
vim.keymap.set("n", "<C-LeftRelease>", mc.handleMouseRelease)

mc.addKeymapLayer(function(layerSet)
	layerSet({ "n", "x" }, "<Left>", mc.prevCursor)
	layerSet({ "n", "x" }, "<Right>", mc.nextCursor)
	layerSet({ "n", "x" }, "<leader>x", mc.deleteCursor)
	layerSet("n", "<Esc>", function()
		if not mc.cursorsEnabled() then
			mc.enableCursors()
		else
			mc.clearCursors()
		end
	end)
end)

-- Autopairs
require("nvim-autopairs").setup({ check_ts = true, fast_wrap = { map = "<M-e>" } })
