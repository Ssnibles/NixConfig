-- Built-in statusline. Replaces zline, so ui2 draws the cmdline and no private
-- API is needed. 'showcmdloc' is "statusline", so '%S' has to stay.
local M = {}
local severities = {
	{ vim.diagnostic.severity.ERROR, "E" },
	{ vim.diagnostic.severity.WARN, "W" },
	{ vim.diagnostic.severity.INFO, "I" },
	{ vim.diagnostic.severity.HINT, "H" },
}
local modes = {
	n = { "NORMAL", "StlModeN" },
	i = { "INSERT", "StlModeI" },
	R = { "REPLACE", "StlModeR" },
	v = { "VISUAL", "StlModeV" },
	V = { "V-LINE", "StlModeV" },
	["\22"] = { "V-BLOCK", "StlModeV" },
	c = { "COMMAND", "StlModeC" },
	s = { "SELECT", "StlModeS" },
	S = { "S-LINE", "StlModeS" },
	t = { "TERMINAL", "StlModeT" },
}
local labels = { qf = "QUICKFIX", help = "HELP", man = "MAN", checkhealth = "HEALTH", oil = "OIL" }
local function escape(text)
	return (text:gsub("%%", "%%%%"))
end
local function mode()
	local current = vim.api.nvim_get_mode().mode
	if current:sub(1, 2) == "nt" then
		return "TERMINAL", "StlModeT"
	end
	local entry = modes[current:sub(1, 1)] or modes.n
	return entry[1], entry[2]
end
local function git()
	local status = vim.b.gitsigns_status_dict
	if not status then
		return ""
	end
	local parts = {}
	if vim.b.gitsigns_head and vim.b.gitsigns_head ~= "" then
		parts[#parts + 1] = vim.b.gitsigns_head
	end
	for _, field in ipairs({ { "added", "+" }, { "changed", "~" }, { "removed", "-" } }) do
		local count = status[field[1]] or 0
		if count > 0 then
			parts[#parts + 1] = field[2] .. count
		end
	end
	return table.concat(parts, " ")
end
local function diagnostics()
	local counts = vim.diagnostic.count(0)
	local parts = {}
	for _, severity in ipairs(severities) do
		local count = counts[severity[1]]
		if count and count > 0 then
			parts[#parts + 1] = severity[2] .. count
		end
	end
	return table.concat(parts, " ")
end
local function clients()
	local names = {}
	for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
		if client.name ~= "" then
			names[#names + 1] = client.name
		end
	end
	return table.concat(names, ",")
end
local function search()
	if vim.v.hlsearch == 0 then
		return ""
	end
	local count = vim.fn.searchcount({ maxcount = 999, timeout = 100 })
	local current, total = count.current, count.total
	if not current or not total or total == 0 then
		return ""
	end
	return ("%d/%s"):format(current, count.incomplete == 2 and (total .. "+") or tostring(total))
end
local function debugging()
	if package.loaded.dap and require("dap").session() then
		return "DAP"
	end
	return ""
end
local function buffer_name()
	local buftype, filetype = vim.bo.buftype, vim.bo.filetype
	if buftype == "terminal" then
		return "TERMINAL"
	end
	if labels[filetype] then
		return labels[filetype]
	end
	if filetype:find("^grug%-far") then
		return "GRUG-FAR"
	end
	if vim.api.nvim_buf_get_name(0) == "" then
		return "[No Name]"
	end
	return "%<%f%m%r"
end
local function text(parts, highlight, value)
	if value and value ~= "" then
		parts[#parts + 1] = ("%%#%s#%s%%*"):format(highlight, escape(value))
	end
end
--- @return string
function M.render()
	local parts = {}
	local name, highlight = mode()
	parts[#parts + 1] = ("%%#%s# %s %%*"):format(highlight, name)
	text(parts, "StlGit", git())
	text(parts, "StlDiag", diagnostics())
	parts[#parts + 1] = "%#StlFile#" .. buffer_name() .. "%*"
	text(parts, "StlFT", vim.bo.filetype)
	parts[#parts + 1] = "%="
	text(parts, "StlLSP", clients())
	text(parts, "StlDiag", search())
	text(parts, "StlFT", vim.wo.spell and "SPELL" or "")
	text(parts, "StlGit", debugging())
	parts[#parts + 1] = "%#StlPos#%S %l:%c%*"
	return table.concat(parts, " ")
end
vim.o.statusline = "%!v:lua.require('ui.statusline').render()"
return M
