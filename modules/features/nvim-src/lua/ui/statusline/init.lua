-- Statusline in the style of the old zline setup, built on the native
-- 'statusline' expression. The command line is not rendered here; ui2 owns it.

local context = require("ui.statusline.context")
local filename = require("ui.statusline.filename")
local info = require("ui.statusline.info")
local mode = require("ui.statusline.mode")

local M = {}

local function escape(text)
	return (tostring(text):gsub("%%", "%%%%"))
end

-- Display width of a formatted segment, ignoring highlight transitions and
-- statusline items such as %<, %= and %S.
local function width(text)
	local plain = text:gsub("%%#.-#", ""):gsub("%%%%", "%%"):gsub("%%.", "")
	return vim.api.nvim_strwidth(plain)
end

local function render_parts(parts)
	local output = {}
	local total = 0
	for _, component in ipairs(parts) do
		local text = component()
		if text then
			output[#output + 1] = text
			total = total + width(text)
		end
	end
	return table.concat(output), total
end

local function inactive(win)
	local buf = vim.api.nvim_win_get_buf(win)
	local name = vim.api.nvim_buf_get_name(buf)
	local path = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
	local line = vim.api.nvim_win_get_cursor(win)[1]
	return ("%%#StlBarNC#%%< %s %%= %d/%d %%#StlBarNC#"):format(escape(path), line, vim.api.nvim_buf_line_count(buf))
end

--- @return string
function M.render()
	local current = vim.api.nvim_get_current_win()
	local target = vim.g.statusline_winid
	if not target or target == 0 then
		target = current
	end
	if target ~= current and vim.api.nvim_win_is_valid(target) then
		return inactive(target)
	end

	local left, left_width =
		render_parts({ mode.mode, mode.selection, mode.macro, context.search, context.git, context.diagnostics })
	local right, right_width = render_parts({ info.dap, info.format_warn, info.filetype, info.position })
	local columns = vim.o.laststatus == 3 and vim.o.columns or vim.api.nvim_win_get_width(current)
	local available = math.max(10, columns - left_width - right_width - 7)
	return "%#StlBar#" .. left .. "%<" .. "%#StlFile#" .. filename.render(available) .. "%#StlBar#%=" .. right
end

vim.o.statusline = "%!v:lua.require('ui.statusline').render()"

return M
