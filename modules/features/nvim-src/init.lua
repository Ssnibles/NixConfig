vim.loader.enable()

for _, dev_plugin in ipairs({
	"/home/josh/sshinator.nvim",
	"/home/josh/indentinator.nvim",
	"/home/josh/zline.nvim",
}) do
	if vim.uv.fs_stat(dev_plugin) then
		vim.opt.runtimepath:append(dev_plugin)
	end
end

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

if not vim.env.NVIM_LISTEN_ADDRESS then
	vim.env.NVIM_LISTEN_ADDRESS = "/tmp/nvim.socket"
end

vim.opt.updatetime = 250
vim.opt.timeoutlen = 500
vim.opt.jumpoptions = "view"
vim.opt.diffopt:append("vertical")
vim.opt.diffopt:append("linematch:60")
vim.opt.display = "lastline"
vim.opt.whichwrap:append("<,>,[,],h,l")
vim.opt.sessionoptions:append("globals")
vim.opt.scrolloff = 999
vim.opt.sidescrolloff = 8
vim.opt.list = false
vim.opt.joinspaces = false
vim.opt.fillchars = { eob = " ", foldopen = "▾", foldclose = "▸", foldsep = "│", diff = "╱", lastline = "…" }
vim.opt.grepprg = "rg --vimgrep --smart-case --hidden"
vim.opt.smoothscroll = true

vim.opt.shortmess:append("CF")

require("keymaps")
require("autocmds")
require("diagnostics")

require("theme").setup()

vim.api.nvim_create_user_command("Mes", 'new | put =execute("messages")', {})

local plugins = require("plugins.registry")
require("bootstrap").load_modules(plugins.core, plugins.deferred)
