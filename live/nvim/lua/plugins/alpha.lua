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

local orig_redraw = alpha.redraw
alpha.redraw = function(...)
  pcall(orig_redraw, ...)
end

alpha.setup(dashboard.config)

vim.api.nvim_create_autocmd("FileType", {
  pattern = "alpha",
  desc = "Disable cursorline and indent scope on alpha",
  callback = function()
    vim.wo.cursorline = false
    vim.b.miniindentscope_disable = true
  end,
})

vim.api.nvim_create_autocmd("WinEnter", {
  desc = "Toggle display settings for alpha",
  callback = function()
    if vim.bo.filetype == "alpha" then
      vim.opt.laststatus = 0
      vim.wo.cursorline = false
      vim.b.miniindentscope_disable = true
      pcall(require("lualine").hide)
    else
      vim.opt.laststatus = 3
      pcall(require("lualine").hide, { unhide = true })
    end
  end,
})
