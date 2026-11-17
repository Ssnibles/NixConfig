-- Mode, visual selection and macro recording segments.

local icons = require("ui.statusline.icons")
local util = require("ui.statusline.util")

local M = {}

local modes = {
	n = { "N", "StlModeN" },
	no = { "O-P", "StlModeN" },
	nov = { "O-P", "StlModeN" },
	noV = { "O-P", "StlModeN" },
	["no\22"] = { "O-P", "StlModeN" },
	i = { "I", "StlModeI" },
	ic = { "I", "StlModeI" },
	ix = { "I", "StlModeI" },
	v = { "V", "StlModeV" },
	V = { "V", "StlModeV" },
	["\22"] = { "V", "StlModeV" },
	s = { "S", "StlModeS" },
	S = { "S", "StlModeS" },
	["\19"] = { "S", "StlModeS" },
	c = { "C", "StlModeC" },
	cv = { "C", "StlModeC" },
	ce = { "C", "StlModeC" },
	t = { "T", "StlModeT" },
	nt = { "T-N", "StlModeT" },
	ntT = { "T-N", "StlModeT" },
	R = { "R", "StlModeR" },
	r = { "R", "StlModeR" },
	rm = { "R", "StlModeR" },
	Rc = { "R", "StlModeR" },
	Rx = { "R", "StlModeR" },
	["!"] = { "!", "StlModeC" },
}

function M.mode()
	local current = vim.api.nvim_get_mode().mode
	local entry = modes[current] or { current:sub(1, 1):upper(), "StlModeN" }
	return ("%%#%s# %s %%#StlBar#"):format(entry[2], entry[1])
end

function M.selection()
	local current = vim.api.nvim_get_mode().mode
	local char = current == "v" or current == "s"
	local line = current == "V" or current == "S"
	local block = current == "\22" or current == "\19"
	if not (char or line or block) then
		return nil
	end
	local first, last = vim.fn.line("v"), vim.fn.line(".")
	local lines = math.abs(last - first) + 1
	if line then
		return ("%%#StlSelection# %dL %%#StlBar#"):format(lines)
	end
	if block then
		local columns = math.abs(vim.fn.virtcol("v") - vim.fn.virtcol(".")) + 1
		return ("%%#StlSelection# %dL%s%dC %%#StlBar#"):format(lines, icons.selection, columns)
	end
	if lines > 1 then
		return ("%%#StlSelection# %dL %%#StlBar#"):format(lines)
	end
	local start_col, end_col = vim.fn.getpos("v")[3], vim.fn.getpos(".")[3]
	local text = vim.fn.getline(first)
	local from = math.max(1, math.min(start_col, end_col))
	local to = math.max(1, math.min(math.max(start_col, end_col), #text))
	local chars = vim.fn.strchars(text:sub(from, to))
	if chars < 1 then
		chars = math.abs(vim.fn.virtcol("v") - vim.fn.virtcol(".")) + 1
	end
	return ("%%#StlSelection# %dc %%#StlBar#"):format(chars)
end

function M.macro()
	local register = vim.fn.reg_recording()
	if register == "" then
		return nil
	end
	return ("%%#StlMacro# %s @%s %%#StlBar#"):format(icons.macro, util.escape(register))
end

return M
