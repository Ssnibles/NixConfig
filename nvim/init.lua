-- ============================================================================
-- CORE OPTIONS
-- ============================================================================
vim.g.mapleader = " "
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.shiftwidth = 2
opt.tabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.termguicolors = true
opt.cursorline = true
opt.scrolloff = 8
opt.signcolumn = "yes"
opt.ignorecase = true
opt.smartcase = true
opt.updatetime = 200
opt.undofile = true
opt.clipboard = "unnamedplus"

-- ============================================================================
-- DIAGNOSTIC UI & LINE HIGHLIGHTING
-- ============================================================================
vim.api.nvim_set_hl(0, "DiagLineError", { bg = "#2d1a1a" })
vim.api.nvim_set_hl(0, "DiagLineWarn", { bg = "#2d2a1a" })

vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN]  = "󰀪",
      [vim.diagnostic.severity.HINT]  = "󰌶",
      [vim.diagnostic.severity.INFO]  = "󰋽",
    },
    linehl = {
      [vim.diagnostic.severity.ERROR] = "DiagLineError",
      [vim.diagnostic.severity.WARN]  = "DiagLineWarn",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticError",
      [vim.diagnostic.severity.WARN]  = "DiagnosticWarn",
    },
  },
  underline = true,
  severity_sort = true,
  float = { border = "rounded", source = "always" },
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search")
map("n", "<leader>v", "<C-w>v", "Split vertical")
map("n", "<leader>h", "<C-w>s", "Split horizontal")
map("n", "<leader>c", "<C-w>c", "Close window")

-- LSP & Diagnostics
map("n", "gd", vim.lsp.buf.definition, "Go to definition")
map("n", "K", vim.lsp.buf.hover, "Hover")
map("n", "<leader>a", vim.lsp.buf.code_action, "Code action")
map("n", "<leader>r", vim.lsp.buf.rename, "Rename")
map("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end, "Format")
map("n", "[d", vim.diagnostic.goto_prev, "Prev diagnostic")
map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")

-- Navigation (smart-splits)
local function move(dir)
  local ok, ss = pcall(require, "smart-splits")
  if ok then
    ss["move_cursor_" .. dir]()
  else
    vim.cmd("wincmd " .. ({ left = "h", down = "j", up = "k", right = "l" })[dir])
  end
end
map("n", "<C-h>", function() move("left") end)
map("n", "<C-j>", function() move("down") end)
map("n", "<C-k>", function() move("up") end)
map("n", "<C-l>", function() move("right") end)

-- ============================================================================
-- PLUGINS SETUP
-- ============================================================================

-- Statuscol
local has_statuscol, statuscol = pcall(require, "statuscol")
if has_statuscol then
  local builtin = require("statuscol.builtin")
  statuscol.setup({
    relculright = true,
    segments = {
      { text = { builtin.diagnostic_signs }, click = "v:lua.ScSa" },
      { text = { "%s" },                     click = "v:lua.ScSa" },
      { text = { builtin.lnumfunc, " " },    click = "v:lua.ScLa" },
    },
  })
end

-- Blink
local has_blink, blink = pcall(require, "blink.cmp")
if has_blink then
  blink.setup({
    keymap = { preset = 'super-tab' },
    appearance = { use_nvim_cmp_as_default = true, nerd_font_variant = 'mono' },
    completion = {
      ghost_text = { enabled = true },
      menu = { draw = { columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } } } },
      documentation = { auto_show = true, window = { border = 'rounded' } },
    },
    signature = { enabled = true, window = { border = 'rounded' } },
    sources = { default = { 'lsp', 'path', 'snippets', 'buffer' } },
  })
end

-- Oil
if pcall(require, "oil") then
  require("oil").setup({ view_options = { show_hidden = true } })
  map("n", "-", "<cmd>Oil<CR>", "Open Oil")
end

-- Telescope
if pcall(require, "telescope") then
  require("telescope").setup({ defaults = { borderchars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" } } })
  local tel = require("telescope.builtin")
  map("n", "<leader>ff", tel.find_files)
  map("n", "<leader>fg", tel.live_grep)
  map("n", "<leader>fb", tel.buffers)
end

-- Autopairs
if pcall(require, "nvim-autopairs") then require("nvim-autopairs").setup({ check_ts = true }) end

-- Treesitter
local has_ts, ts_configs = pcall(require, "nvim-treesitter.configs")
if has_ts then
  ts_configs.setup({ highlight = { enable = true }, indent = { enable = true }, auto_install = false })
end

-- ============================================================================
-- LSP (Nixd + LuaLS)
-- ============================================================================
local lsp = require("lspconfig")
local caps = has_blink and blink.get_lsp_capabilities() or nil

-- Nixd Fix for Flakes
lsp.nixd.setup({
  capabilities = caps,
  settings = {
    nixd = {
      nixpkgs = { expr = "import (builtins.getFlake \"/home/josh/NixConfig\").inputs.nixpkgs { }" },
      formatting = { command = { "nixpkgs-fmt" } },
      options = {
        nixos = { expr = "(builtins.getFlake \"/home/josh/NixConfig\").nixosConfigurations.nixos.options" },
      },
    },
  },
})

lsp.lua_ls.setup({
  capabilities = caps,
  settings = { Lua = { diagnostics = { globals = { "vim" } }, workspace = { checkThirdParty = false } } }
})

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================
local group = vim.api.nvim_create_augroup("NixOSConfig", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = group,
  callback = function(ev)
    if not ev.match:match("^%w+://") then
      local dir = vim.fn.fnamemodify(ev.file, ":h")
      if vim.fn.isdirectory(dir) == 0 then vim.fn.mkdir(dir, "p") end
    end
    local ft = vim.bo[ev.buf].filetype
    if ft == "nix" or ft == "lua" then
      vim.lsp.buf.format({ bufnr = ev.buf, async = false })
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", { group = group, callback = function() vim.highlight.on_yank() end })
vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
