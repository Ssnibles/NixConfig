local c = require("theme").colors
local t = require("theme")

require("lualine").setup({
	options = {
		theme = t.lualine,
		component_separators = "",
		section_separators = { left = "", right = "" },
		globalstatus = true,
	},
	sections = {
		lualine_a = { {
			"mode",
			fmt = function(str)
				return " " .. str:sub(1, 1) .. " "
			end,
		} },
		lualine_b = {
			{ "branch", icon = { " ", align = "left" }, color = { fg = c.comment } },
			{
				"diff",
				colored = true,
				symbols = { added = "+", modified = "~", removed = "-" },
				diff_color = { added = { fg = c.green }, modified = { fg = c.yellow }, removed = { fg = c.red } },
			},
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = "×", warn = "▲", info = "•", hint = "•" },
				padding = { left = 1, right = 0 },
			},
		},
		lualine_c = {
			{ "filename", path = 1, symbols = { modified = " ", readonly = " ", new = " ", unnamed = "[No Name]" } },
		},
		lualine_x = {
			{
				function()
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					if #clients == 0 then
						return ""
					end
					local names = {}
					for _, client in ipairs(clients) do
						names[#names + 1] = client.name
					end
					return table.concat(names, ", ")
				end,
				icon = { "  ", align = "left" },
				color = { fg = c.comment },
				cond = function()
					return #vim.lsp.get_clients({ bufnr = 0 }) > 0 and vim.bo.filetype ~= ""
				end,
			},
		},
		lualine_y = { { "filetype", colored = false, padding = { left = 1, right = 1 } } },
		lualine_z = {
			{
				function()
					return vim.fn.line(".") .. "/" .. vim.fn.line("$")
				end,
				padding = { left = 1, right = 1 },
			},
		},
	},
	extensions = {},
})

local function statuscolumn()
	local foldcol = ""
	local signcol = "%s"
	local numcol = ""

	local foldcolumn = tonumber(vim.wo.foldcolumn) or 0
	if foldcolumn > 0 then
		local lnum = vim.v.lnum
		local foldclosed = vim.fn.foldclosed(lnum)
		local foldlevel = vim.fn.foldlevel(lnum)

		if foldclosed > 0 then
			foldcol = "▸"
		elseif foldlevel > 0 then
			foldcol = "▾"
		else
			foldcol = " "
		end
		foldcol = foldcol .. " "
	end

	local lnum = vim.v.lnum
	local lastlnum = tonumber(vim.fn.line("$")) or 1
	local width = #tostring(lastlnum)

	if vim.v.relnum == 0 then
		numcol = string.format("%" .. width .. "d ", lnum)
	else
		numcol = string.format("%" .. width .. "d ", vim.v.relnum)
	end

	return foldcol .. signcol .. numcol
end

vim.o.statuscolumn = "%!v:lua.require('plugins.ui').statuscolumn()"

local M = {}
M.statuscolumn = statuscolumn

return M
