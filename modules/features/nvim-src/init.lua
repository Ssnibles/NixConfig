vim.loader.enable()

-- Dev plugins (loaded from local checkouts when present)
for _, path in ipairs({
	"/home/josh/sshinator.nvim",
	"/home/josh/indentinator.nvim",
	"/home/josh/zline.nvim",
	"/home/josh/startinator.nvim",
}) do
	if vim.uv.fs_stat(path) then
		vim.opt.runtimepath:append(path)
	end
end

-- Disable netrw (oil.nvim replaces it)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Editor options
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

-- Listen address for neovim-remote
if not vim.env.NVIM_LISTEN_ADDRESS then
	vim.env.NVIM_LISTEN_ADDRESS = "/tmp/nvim.socket"
end

-- User commands
vim.api.nvim_create_user_command("Mes", 'new | put =execute("messages")', {})

-- Load configuration modules
require("keymaps")
require("autocmds")
require("theme").setup()

-- Plugins (all installed by Nix/NVF as startPlugins — no lazy loader needed)
require("plugins.treesitter")
require("plugins.completion")
require("lsp")
require("plugins.editor")
require("plugins.format")
require("plugins.mini")
require("plugins.fzf")
require("plugins.lint")
require("plugins.dap")
require("plugins.terminal")
require("plugins.lang")
require("messages").setup()

-- Set after plugins so nothing overrides it
vim.o.statuscolumn = "%s%=%{v:relnum?v:relnum:v:lnum} %#WinSeparator#▏%*"
