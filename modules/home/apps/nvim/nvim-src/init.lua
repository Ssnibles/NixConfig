-- Neovim configuration entry point

-- Enable bytecode caching for faster startup (Neovim 0.9+).
pcall(vim.loader.enable)

if not vim.env.NVIM_LISTEN_ADDRESS then
	vim.env.NVIM_LISTEN_ADDRESS = "/tmp/nvim.socket"
end

-- Modern defaults ----------------------------------------------------
vim.opt.smoothscroll = true     -- Partial-line scrolling at viewport edges
vim.opt.jumpoptions = "view"    -- Smarter jump list
vim.opt.diffopt:append("vertical") -- Vertical split for diffs
vim.opt.diffopt:append("linematch:60") -- Better diff alignment
vim.opt.display = "lastline"    -- Show partial last line instead of @
vim.opt.whichwrap:append("<,>,[,],h,l") -- Cursor keys wrap between lines
vim.opt.sessionoptions:append("globals") -- Save globals in sessions

require("keymaps")
require("autocmds")
require("diagnostics")

require("theme").setup()

local bootstrap = require("bootstrap")
local plugins = require("plugins.registry")

bootstrap.load_modules(plugins.core)
bootstrap.defer_modules(plugins.deferred, "VimEnter")
