-- Neovim configuration entry point
require("keymaps")
require("autocmds")
require("diagnostics")

require("theme").setup()

local bootstrap = require("bootstrap")
local plugins = require("plugins.registry")

bootstrap.load_modules(plugins.core)
bootstrap.defer_modules(plugins.deferred, "VimEnter")
