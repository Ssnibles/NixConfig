-- Statusline icons. File and filetype icons come from mini.icons, the rest are
-- fixed Nerd Font glyphs like the old zline setup.

local M = {
	git = "",
	error = "󰅚",
	warn = "󰀦",
	search = "󰍉",
	dap = "󰃤",
	macro = "󰑋",
	selection = "×",
	warn_fmt = "⚠",
}

--- @param name string
--- @param filetype string
--- @return string|nil icon
--- @return string|nil highlight
function M.file(name, filetype)
	local icons = require("mini.icons")
	if name ~= "" then
		return icons.get("file", name)
	end
	return icons.get("filetype", filetype)
end

return M
