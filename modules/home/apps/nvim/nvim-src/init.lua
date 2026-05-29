-- Neovim configuration entry point

vim.loader.enable()

if not vim.env.NVIM_LISTEN_ADDRESS then
	vim.env.NVIM_LISTEN_ADDRESS = "/tmp/nvim.socket"
end

vim.opt.smoothscroll = true
vim.opt.jumpoptions = "view"
vim.opt.diffopt:append("vertical")
vim.opt.diffopt:append("linematch:60")
vim.opt.display = "lastline"
vim.opt.whichwrap:append("<,>,[,],h,l")
vim.opt.sessionoptions:append("globals")

require("keymaps")
require("autocmds")
require("diagnostics")

require("theme").setup()

local plugins = require("plugins.registry")
require("bootstrap").load_modules(plugins.core, plugins.deferred)
