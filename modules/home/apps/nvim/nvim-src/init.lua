-- Neovim configuration entry point

vim.loader.enable()

-- Disable netrw so oil.nvim can fully take over as the default file explorer.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

if not vim.env.NVIM_LISTEN_ADDRESS then
	vim.env.NVIM_LISTEN_ADDRESS = "/tmp/nvim.socket"
end

-- Essential UX defaults
vim.opt.clipboard = "unnamedplus"
vim.opt.undofile = true
vim.opt.updatetime = 250
vim.opt.timeoutlen = 500
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.jumpoptions = "view"
vim.opt.diffopt:append("vertical")
vim.opt.diffopt:append("linematch:60")
vim.opt.display = "lastline"
vim.opt.whichwrap:append("<,>,[,],h,l")
vim.opt.sessionoptions:append("globals")
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8
vim.opt.list = false
vim.opt.joinspaces = false
vim.opt.fillchars = { eob = " " }
vim.opt.grepprg = "rg --vimgrep --smart-case --hidden"
vim.opt.grepformat = "%f:%l:%c:%m"
vim.opt.smoothscroll = true

-- UI polish
vim.opt.shortmess:append("CF")

require("keymaps")
require("autocmds")
require("diagnostics")

require("theme").setup()

vim.api.nvim_create_user_command("Mes", 'new | put =execute("messages")', {})

local plugins = require("plugins.registry")
require("bootstrap").load_modules(plugins.core, plugins.deferred)
