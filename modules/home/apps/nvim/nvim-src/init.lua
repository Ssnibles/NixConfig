-- Neovim configuration entry point

vim.loader.enable()

-- Disable netrw so oil.nvim can fully take over as the default file explorer.
-- Without this, oil's buffer can render empty when it conflicts with netrw.
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

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

-- Essential UX defaults
vim.opt.clipboard = "unnamedplus"        -- sync with system clipboard
vim.opt.undofile = true                   -- persistent undo
vim.opt.updatetime = 250                  -- faster CursorHold, diagnostic float, etc.
vim.opt.timeoutlen = 500                  -- snappier which-key / leader delays
vim.opt.ignorecase = true                 -- case-insensitive search…
vim.opt.smartcase = true                  -- …unless uppercase is typed
vim.opt.hidden = true                     -- allow switching buffers without saving
vim.opt.confirm = true                    -- confirm unsaved changes instead of failing
vim.opt.signcolumn = "yes"                -- always show sign column (prevents layout shift)
vim.opt.cursorline = true                 -- highlight current line
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.termguicolors = true              -- true-color support
vim.opt.scrolloff = 4                     -- keep cursor away from screen edge
vim.opt.sidescrolloff = 8
vim.opt.wrap = false                      -- no soft-wrap by default
vim.opt.linebreak = true                  -- when wrap IS on, break at word boundaries
vim.opt.list = false                      -- don't show invisible chars by default
vim.opt.joinspaces = false                -- no double spaces after `.` on join
vim.opt.splitbelow = true                 -- open horizontal splits below
vim.opt.splitright = true                 -- open vertical splits to the right
vim.opt.virtualedit = "block"             -- free cursor movement in visual block mode
vim.opt.fillchars = { eob = " " }         -- hide `~` at end of buffer
vim.opt.mouse = "a"                       -- full mouse support
vim.opt.grepprg = "rg --vimgrep --smart-case --hidden"
vim.opt.grepformat = "%f:%l:%c:%m"

-- UI polish: hide redundant mode text (lualine shows it), live substitution preview
vim.opt.showmode = false
vim.opt.inccommand = "split"
vim.opt.shortmess:append("cC")            -- suppress completion and `scanning` messages

require("keymaps")
require("autocmds")
require("diagnostics")

require("theme").setup()

vim.api.nvim_create_user_command("Mes", 'new | put =execute("messages")', {})

local plugins = require("plugins.registry")
require("bootstrap").load_modules(plugins.core, plugins.deferred)
