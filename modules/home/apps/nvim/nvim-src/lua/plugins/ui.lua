-- UI: lualine, statuscol.

local c = require("theme").colors
local t = require("theme")

-- ═══════════════════════════════════════════════════════════════════
--  L U A L I N E
-- ═══════════════════════════════════════════════════════════════════

require("lualine").setup({
	options = {
		theme = t.lualine,
		component_separators = "",
		section_separators = { left = "", right = "" },
		globalstatus = true,
	},
	sections = {
		lualine_a = {
			{
				"mode",
				fmt = function(str)
					return " " .. str:sub(1, 1) .. " "
				end,
			},
		},
		lualine_b = {
			{
				"branch",
				icon = { " ", align = "left" },
				color = { fg = c.comment },
			},
			{
				"diff",
				colored = true,
				symbols = { added = "+", modified = "~", removed = "-" },
				diff_color = {
					added = { fg = c.green },
					modified = { fg = c.yellow },
					removed = { fg = c.red },
				},
			},
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				symbols = { error = "×", warn = "▲", info = "•", hint = "•" },
				padding = { left = 1, right = 0 },
			},
		},
		lualine_c = {
			{
				"filename",
				path = 1,
				symbols = { modified = " ", readonly = " ", new = " ", unnamed = "[No Name]" },
			},
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
		lualine_y = {
			{
				"filetype",
				colored = false,
				padding = { left = 1, right = 1 },
			},
		},
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

-- ═══════════════════════════════════════════════════════════════════
--  S T A T U S C O L
-- ═══════════════════════════════════════════════════════════════════

local builtin = require("statuscol.builtin")
require("statuscol").setup({
	relculright = true,
	segments = {
		{ text = { builtin.foldfunc }, click = "v:lua.ScFa" },
		{ text = { "%s" }, click = "v:lua.ScSa" },
		{ text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
	},
})

-- cmdline handled by tiny-cmdline plugin


