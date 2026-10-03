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

-- Message/cmdline presentation (Neovim 0.12+ "ui2"). This is what makes
-- 'cmdheight=0' usable: messages are drawn in a transient floating "msg"
-- window that auto-dismisses, and the legacy hit-enter "Press ENTER" prompt
-- (which has nowhere to draw when cmdheight=0) no longer exists.
-- NOTE: do NOT attach another `vim.ui_attach(..., { ext_messages = true })`
-- UI on top of this. ext_messages externalizes *all* message rendering, so any
-- kind it does not explicitly draw silently disappears (this was the cause of
-- `:!cmd` output vanishing and the editor appearing to freeze).
require("vim._core.ui2").enable({
  msg = {
    -- Ephemeral messages (`:!` output, `:echo`, errors, …) go to the floating
    -- message window instead of the cmdline, so they auto-dismiss.
    targets = { default = "msg" },
  },
})
-- `wait` is required whenever `hit-enter` is omitted. `timeout` is how long a
-- message stays visible in the message window (ms).
vim.o.messagesopt = "history:200,wait:0,timeout:4000,maxheight:50,pager:<CR>"

-- zline.nvim owns the cmdline: it captures `ext_cmdline` events and renders the
-- line into the statusline. ui2 also claims cmdline events and draws its own
-- 'cmd' window, so both would be shown at once. ui2 exposes no option to opt out
-- of the cmdline, so drop its cmdline event handlers; message handling is
-- unaffected. If a future Neovim renames these methods this simply becomes a
-- no-op and the duplicate would return (not an error).
do
  local ui2 = require("vim._core.ui2")
  if ui2.cmd then
    for _, ev in ipairs({
      "cmdline_show",
      "cmdline_pos",
      "cmdline_hide",
      "cmdline_special_char",
      "cmdline_block_show",
      "cmdline_block_append",
      "cmdline_block_hide",
    }) do
      ui2.cmd[ev] = nil
    end
  end
end

-- Listen address for neovim-remote.
-- Nvim (with NVIM_APPNAME=nvf) already starts a server, so point children at
-- the real socket instead of a path we never actually listen on.
if vim.v.servername ~= "" then
	vim.env.NVIM_LISTEN_ADDRESS = vim.v.servername
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
require("plugins.diagnostics")
require("plugins.markview")
require("plugins.dial")

-- Set after plugins so nothing overrides it.
-- v:relnum is *always* the relative offset inside 'statuscolumn', regardless
-- of whether 'relativenumber' is set, so the option has to be tested explicitly.
-- Without the guard the column never switches to absolute numbers (e.g. while
-- in insert mode, or after <leader>tn).
vim.o.statuscolumn = "%s%=%{&relativenumber && v:relnum ? v:relnum : v:lnum} %#WinSeparator#▏%*"
