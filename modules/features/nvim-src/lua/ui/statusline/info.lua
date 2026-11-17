-- Right-hand segments: debugger, format warnings, filetype and position.

local icons = require("ui.statusline.icons")
local util = require("ui.statusline.util")

local M = {}

function M.dap()
	local dap = package.loaded.dap
	if not dap or type(dap.status) ~= "function" then
		return nil
	end
	local status = dap.status()
	if not status or status == "" then
		return nil
	end
	return ("%%#StlDap# %s %s %%#StlBar#"):format(icons.dap, util.escape(status))
end

function M.format_warn()
	local format = vim.bo.fileformat
	local encoding = vim.bo.fileencoding
	local problems = {}
	if format ~= "" and format ~= "unix" then
		problems[#problems + 1] = format:upper()
	end
	if encoding ~= "" and encoding ~= "utf-8" and encoding ~= "utf8" then
		problems[#problems + 1] = encoding:upper()
	end
	if #problems == 0 then
		return nil
	end
	return ("%%#StlWarn# %s %s %%#StlBar#"):format(icons.warn_fmt, table.concat(problems, " "))
end

function M.filetype()
	local ft = vim.bo.filetype
	if ft == "" then
		return nil
	end
	local icon, highlight = icons.file(vim.api.nvim_buf_get_name(0), ft)
	local icon_text = ""
	if icon and icon ~= "" then
		icon_text = ("%%#%s#%s %%#StlFT#"):format(highlight or "StlFT", util.escape(icon))
	end
	return ("%%#StlFT# %s%s %%#StlBar#"):format(icon_text, util.escape(ft))
end

function M.position()
	local line = vim.api.nvim_win_get_cursor(0)[1]
	return ("%%#StlPos# %d/%d %%#StlBar#"):format(line, vim.api.nvim_buf_line_count(0))
end

return M
