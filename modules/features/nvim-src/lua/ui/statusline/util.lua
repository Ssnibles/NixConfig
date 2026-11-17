local M = {}

--- Escape literal data for a statusline string.
--- @param text any
--- @return string
function M.escape(text)
	return (tostring(text):gsub("%%", "%%%%"))
end

return M
