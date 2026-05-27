local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
	"                                                     ",
	"  ███╗   ██╗██╗██╗  ██╗ ██████╗ ██████╗ ███╗   ██╗ ",
	"  ████╗  ██║██║╚██╗██╔╝██╔════╝██╔═══██╗████╗  ██║ ",
	"  ██╔██╗ ██║██║ ╚███╔╝ ██║     ██║   ██║██╔██╗ ██║ ",
	"  ██║╚██╗██║██║ ██╔██╗ ██║     ██║   ██║██║╚██╗██║ ",
	"  ██║ ╚████║██║██╔╝ ██╗╚██████╗╚██████╔╝██║ ╚████║ ",
	"  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝ ",
	"                                                     ",
}

dashboard.section.buttons.val = {
	dashboard.button("e", "    New file", ":ene <BAR> startinsert<CR>"),
	dashboard.button("f", "  󰈞  Find file", ":FzfLua files<CR>"),
	dashboard.button("g", "    Live grep", ":FzfLua grep<CR>"),
	dashboard.button("r", "    Recent files", ":FzfLua oldfiles<CR>"),
	dashboard.button("q", "  󰅚  Quit", ":qa<CR>"),
}

dashboard.section.footer.val = "nixos"
dashboard.section.footer.opts.hl = "AlphaFooter"

alpha.setup(dashboard.config)

vim.api.nvim_create_autocmd("WinEnter", {
	desc = "Toggle display settings for alpha",
	callback = function()
		if vim.bo.filetype == "alpha" then
			vim.wo.cursorline = false
			vim.b.miniindentscope_disable = true
		end
	end,
})
