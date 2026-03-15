local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = "\\" -- distinct from mapleader; used by filetype plugins

-- ── Line numbers ──────────────────────────────────────────────────────────
opt.number = true
opt.relativenumber = true

-- ── Indentation (2-space soft tabs) ───────────────────────────────────────
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.shiftround = true -- always indent to a multiple of shiftwidth

-- ── Appearance ────────────────────────────────────────────────────────────
opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"
opt.winblend = 8 -- floating window transparency
opt.pumblend = 8 -- completion popup transparency
opt.showmode = false -- lualine shows mode already
opt.conceallevel = 2 -- hide markup chars (markview, etc.)
opt.concealcursor = "nc" -- reveal on cursor in insert/visual
opt.fillchars = {
	fold = " ",
	foldopen = "▾",
	foldclose = "▸",
	foldsep = " ",
	diff = "╱",
	eob = " ", -- suppress ~ at end-of-buffer
}
opt.listchars = {
	trail = "·",
	nbsp = "␣",
	extends = "›",
	precedes = "‹",
}
opt.list = true

-- ── Search ────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.inccommand = "split" -- live preview for :s substitutions

-- ── Splits ────────────────────────────────────────────────────────────────
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen" -- keep text on screen when splitting

-- ── Folds ─────────────────────────────────────────────────────────────────
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevelstart = 99 -- open all folds by default

-- ── Performance / reliability ─────────────────────────────────────────────
opt.updatetime = 200
opt.timeoutlen = 400
opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false

-- ── Wrapping ──────────────────────────────────────────────────────────────
opt.wrap = false
opt.linebreak = true -- if wrap is toggled, break at word boundaries
opt.breakindent = true -- wrapped lines indent to match the parent

-- ── Misc ──────────────────────────────────────────────────────────────────
opt.clipboard = "unnamedplus" -- use system clipboard (needs wl-clipboard)
opt.mouse = "a"
opt.confirm = true -- ask instead of erroring on unsaved changes
opt.virtualedit = "block" -- free-move in visual-block mode
opt.grepprg = "rg --vimgrep --smart-case"
opt.grepformat = "%f:%l:%c:%m"
opt.shortmess:append("sIc") -- suppress intro / ins-completion messages
