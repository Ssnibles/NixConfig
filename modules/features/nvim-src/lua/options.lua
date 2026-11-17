-- Editor options and GUI globals. Grouped by concern; one assignment per line.

local opt = vim.opt
local g = vim.g

-- Neovide (GUI). Read when the window is created.
g.neovide_font_family = "Maple Mono NR NF"
g.neovide_font_size = 12
g.neovide_padding_top = 20
g.neovide_padding_bottom = 20
g.neovide_padding_left = 20
g.neovide_padding_right = 20
g.neovide_refresh_rate = 60
g.neovide_idle = true
g.neovide_vsync = true
g.neovide_cursor_vfx_mode = ""
g.neovide_cursor_animation_length = 0.0
g.neovide_scroll_animation_length = 0.08
g.neovide_floating_blur = false
g.neovide_confirm_quit = true
g.neovide_remember_window_size = true

-- Indentation
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true
opt.shiftround = true

-- Appearance
opt.termguicolors = true
opt.cursorline = true
opt.cursorlineopt = "line"
opt.showmode = false
opt.conceallevel = 2
opt.pumheight = 12
opt.winborder = "rounded"

-- Line numbers and the status column. v:relnum is always the relative offset,
-- so the option has to be tested explicitly or the column never switches to
-- absolute numbers.
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.statuscolumn = "%s%=%{&relativenumber && v:relnum ? v:relnum : v:lnum} %#WinSeparator#▏%*"

-- Wrapping
opt.wrap = false
opt.linebreak = true
opt.breakindent = true

-- Splits and windows
opt.splitright = true
opt.splitbelow = true
opt.laststatus = 3
opt.cmdheight = 0
opt.showcmdloc = "statusline"
opt.scrolloff = 999
opt.sidescrolloff = 8
opt.smoothscroll = true

-- Folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99
opt.foldtext = "v:lua.require('theme').fold_text()"

-- Search
opt.inccommand = "split"
opt.ignorecase = true
opt.smartcase = true
opt.grepprg = "rg --vimgrep --smart-case --hidden"

-- Editing behaviour
opt.confirm = true
opt.swapfile = false
opt.writebackup = false
opt.undofile = true
opt.virtualedit = "block"
opt.mouse = "a"
opt.mousemodel = "extend"
opt.clipboard = "unnamedplus"

-- Command line and messages
opt.wildmode = "longest:full,full"
opt.wildoptions = "fuzzy"
opt.wildignorecase = true
-- Replaces the default instead of appending: the default truncates messages
-- ("t" and "T") and shows a "..." during redraw ("l").
opt.shortmess = "sIcWFoOuCF"
-- `wait` is required whenever `hit-enter` is omitted. `timeout` is how long a
-- message stays in the ui2 message window (ms).
opt.messagesopt = "history:200,wait:0,timeout:4000,maxheight:50,pager:<CR>"

-- Timing
opt.updatetime = 250
opt.timeoutlen = 500
opt.ttimeoutlen = 10

-- Misc
opt.jumpoptions = "view"
opt.diffopt:append("vertical")
opt.diffopt:append("linematch:60")
opt.whichwrap:append("<,>,[,],h,l")
opt.sessionoptions:append("globals")
opt.fillchars = { eob = " ", foldopen = "▾", foldclose = "▸", foldsep = "│", diff = "╱", lastline = "…" }
