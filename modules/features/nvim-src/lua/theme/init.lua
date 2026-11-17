-- Theme: a flat dark palette on mini.base16, plus fold text. The highlight
-- groups are data and live in theme/highlights.lua.

local M = {}

M.colours = {
	bg = "#141415",
	fg = "#cdcdcd",
	comment = "#606079",
	bgSubtle = "#252530",
	border = "#2e2e3c",
	blue = "#6e94b2",
	purple = "#bb9dbd",
	green = "#7fa563",
	red = "#d8647e",
	yellow = "#f3be7c",
	cyan = "#b4d4cf",
	orange = "#e8b589",
	magenta = "#c48282",
	selection = "#2d2d3f",
	search = "#1e2e40",
}

local function blend(fg, bg, alpha)
	local function parse(hex)
		hex = hex:gsub("#", "")
		return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
	end
	local r1, g1, b1 = parse(fg)
	local r2, g2, b2 = parse(bg)
	return string.format(
		"#%02x%02x%02x",
		math.floor(r1 * alpha + r2 * (1 - alpha) + 0.5),
		math.floor(g1 * alpha + g2 * (1 - alpha) + 0.5),
		math.floor(b1 * alpha + b2 * (1 - alpha) + 0.5)
	)
end

function M.setup()
	local c = M.colours
	vim.o.background = "dark"

	require("mini.base16").setup({
		palette = {
			base00 = c.bg,
			base01 = c.bg,
			base02 = c.bg,
			base03 = c.comment,
			base04 = c.comment,
			base05 = c.fg,
			base06 = c.fg,
			base07 = c.fg,
			base08 = c.red,
			base09 = c.orange,
			base0A = c.yellow,
			base0B = c.green,
			base0C = c.cyan,
			base0D = c.blue,
			base0E = c.purple,
			base0F = c.magenta,
		},
	})

	require("theme.highlights").set(c, blend)

	-- mini.base16 clears this, so set it last so plugins can detect the scheme.
	vim.g.colors_name = "minischeme"
end

--- Fold text: the first line, padded with a rule to the window width.
function M.fold_text()
	local line = vim.fn.getline(vim.v.foldstart)
	local width = vim.fn.winwidth(0) - vim.fn.getwinvar(0, "&numberwidth") - 6
	local folded = vim.fn.printf(" %d lines ", vim.v.foldend - vim.v.foldstart + 1)
	local text = line:gsub("\t", string.rep(" ", vim.fn.shiftwidth()))
	if #text > width then
		text = text:sub(1, width) .. "…"
	end
	return text .. string.rep("─", math.max(width - #text - #folded, 1)) .. folded
end

return M
