-- Filename component for the statusline: special buffer headers, a relative
-- path, and left truncation that keeps the tail of the path.

local icons = require("ui.statusline.icons")

local M = {}

local function escape(text)
	return (tostring(text):gsub("%%", "%%%%"))
end

local function width(text)
	return vim.api.nvim_strwidth(text)
end

local special = {
	qf = "QUICKFIX",
	help = "HELP",
	checkhealth = "HEALTH",
	oil = "OIL",
	man = "MAN",
}

--- Keep the tail of a path within `budget` cells.
--- @param path string
--- @param budget integer
--- @return string
local function fit_path(path, budget)
	if width(path) <= budget then
		return path
	end
	local segments = vim.split(path, "/")
	local tail = {}
	local used = 0
	for index = #segments, 1, -1 do
		local segment = segments[index]
		local extra = width(segment) + (#tail > 0 and 1 or 0)
		if used + extra + 2 > budget then
			break
		end
		table.insert(tail, 1, segment)
		used = used + extra
	end
	if #tail == 0 then
		return vim.fn.strcharpart(path, math.max(0, vim.fn.strchars(path) - budget))
	end
	return "…/" .. table.concat(tail, "/")
end

--- @param available integer
--- @return string
function M.render(available)
	local buftype, filetype = vim.bo.buftype, vim.bo.filetype
	local budget = math.max(1, available)

	if buftype == "quickfix" then
		local is_loclist = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1].loclist == 1
		local list = is_loclist and vim.fn.getloclist(0, { idx = 0, size = 0 }) or vim.fn.getqflist({ idx = 0, size = 0 })
		if list.size > 0 then
			return (" [%s %d/%d] "):format(is_loclist and "LOCLIST" or "QUICKFIX", list.idx, list.size)
		end
		return " [QUICKFIX] "
	end
	if buftype == "terminal" then
		local ok, info = pcall(vim.api.nvim_get_chan_info, vim.bo.channel or 0)
		if ok and info.argv and info.argv[1] then
			local command = vim.fn.fnamemodify(info.argv[1], ":t")
			if command ~= "" then
				return (" [%s] "):format(command:upper())
			end
		end
		return " [TERMINAL] "
	end
	if buftype ~= "" then
		return (" [%s] "):format((special[filetype] or buftype):upper())
	end
	if special[filetype] then
		return (" [%s] "):format(special[filetype])
	end
	if filetype:find("^grug%-far") then
		return " [GRUG-FAR] "
	end

	local suffix = (vim.bo.modified and " +" or "") .. (vim.bo.readonly and " =" or "")
	local name = vim.api.nvim_buf_get_name(0)
	if name == "" then
		return " [No Name]" .. suffix .. " "
	end

	local path = vim.fn.fnamemodify(name, ":~:.")
	local icon, highlight = icons.file(name, filetype)
	local icon_text = ""
	if icon and icon ~= "" then
		local group = highlight or "StlFile"
		icon_text = ("%%#%s#%s %%#StlFile#"):format(group, escape(icon))
	end
	local path_budget = math.max(1, budget - width(suffix) - width(icon_text:gsub("%%#.-#", "")) - 3)
	return " " .. icon_text .. escape(fit_path(path, path_budget)) .. suffix .. " "
end

return M
