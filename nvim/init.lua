-- ============================================================================
-- OPTIONS
-- ============================================================================
vim.g.mapleader    = " "

local opt          = vim.opt
opt.number         = true
opt.relativenumber = true
opt.mouse          = "a"
opt.shiftwidth     = 2
opt.tabstop        = 2
opt.expandtab      = true
opt.smartindent    = true
opt.termguicolors  = true
opt.cursorline     = true
opt.scrolloff      = 8
opt.signcolumn     = "yes"
opt.ignorecase     = true
opt.smartcase      = true
opt.updatetime     = 200
opt.undofile       = true
opt.clipboard      = "unnamedplus"

-- ============================================================================
-- COLORSCHEME
-- ============================================================================
vim.cmd.colorscheme("catppuccin-mocha")

-- ============================================================================
-- DIAGNOSTICS
-- ============================================================================
vim.diagnostic.config({
  virtual_text  = { prefix = "●", spacing = 4 },
  signs         = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN]  = "󰀪",
      [vim.diagnostic.severity.HINT]  = "󰌶",
      [vim.diagnostic.severity.INFO]  = "󰋽",
    },
  },
  underline     = true,
  severity_sort = true,
  float         = { border = "rounded", source = "always" },
})

-- ============================================================================
-- KEYMAPS
-- ============================================================================
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search")
map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "-", "<cmd>Oil<CR>", "Open Oil")

-- Window navigation with smart-splits fallback
local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
  map("n", "<C-" .. key .. ">", function()
    local ok, ss = pcall(require, "smart-splits")
    if ok then
      ss["move_cursor_" .. dir]()
    else
      vim.cmd("wincmd " .. key)
    end
  end, "Move " .. dir)
end

-- ============================================================================
-- PLUGINS
-- ============================================================================
require("which-key").setup({ window = { border = "rounded" } })
require("gitsigns").setup({})
require("noice").setup()
require("oil").setup({ view_options = { show_hidden = true } })
require("nvim-autopairs").setup({ check_ts = true })
require("luasnip.loaders.from_vscode").lazy_load()

require("fidget").setup({
  notification = { window = { winblend = 0, border = "rounded" } },
})

require("blink.cmp").setup({
  keymap     = { preset = "super-tab" },
  completion = { ghost_text = { enabled = true } },
  sources    = { default = { "lsp", "path", "snippets", "buffer" } },
})

local builtin = require("statuscol.builtin")
require("statuscol").setup({
  relculright = true,
  segments = {
    { text = { builtin.foldfunc },      click = "v:lua.ScFa" },
    { text = { "%s" },                  click = "v:lua.ScSa" },
    { text = { builtin.lnumfunc, " " }, click = "v:lua.ScLa" },
  },
  ft_ignore = { "neo-tree", "lazy", "mason" },
})

local ok, ts = pcall(require, "nvim-treesitter.configs")
if ok then
  ts.setup({ highlight = { enable = true }, indent = { enable = true }, auto_install = false })
end

local tel = require("telescope.builtin")
map("n", "<leader>ff", tel.find_files, "Find files")
map("n", "<leader>fg", tel.live_grep, "Live grep")
map("n", "<leader>fb", tel.buffers, "Buffers")

-- ============================================================================
-- LSP
-- ============================================================================
local lsp         = require("lspconfig")
local base_caps   = vim.lsp.protocol.make_client_capabilities()

-- Merge blink.cmp capabilities once, reuse everywhere
local ok_b, blink = pcall(require, "blink.cmp")
local caps        = ok_b
    and vim.tbl_deep_extend("force", base_caps, blink.get_lsp_capabilities())
    or base_caps

local function on_attach(_, bufnr)
  local o = { buffer = bufnr, noremap = true, silent = true }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", o, { desc = "Go to definition" }))
  vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", o, { desc = "Hover" }))
  vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, vim.tbl_extend("force", o, { desc = "Code action" }))
  vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, vim.tbl_extend("force", o, { desc = "Rename" }))
  vim.keymap.set("n", "<leader>f", function() vim.lsp.buf.format({ async = true }) end,
    vim.tbl_extend("force", o, { desc = "Format" }))
end

local function setup_lsp(name, config)
  lsp[name].setup(vim.tbl_deep_extend("force", { on_attach = on_attach, capabilities = caps }, config or {}))
end

setup_lsp("nixd", {})
setup_lsp("lua_ls", { settings = { Lua = { diagnostics = { globals = { "vim" } } } } })
setup_lsp("kotlin_language_server", {})
setup_lsp("jdtls", { cmd = { "jdtls" } })

-- ============================================================================
-- AUTOCOMMANDS
-- ============================================================================
local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group    = group,
  callback = function() vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 }) end,
})

-- ============================================================================
-- DIAGNOSTIC LINE NUMBER HIGHLIGHTS
-- ============================================================================
local diag_ns = vim.api.nvim_create_namespace("diag_linenum_hl")

local severity_hl = {
  [vim.diagnostic.severity.ERROR] = { sign = "DiagnosticSignError", line = "DiagnosticVirtualTextError" },
  [vim.diagnostic.severity.WARN]  = { sign = "DiagnosticSignWarn",  line = "DiagnosticVirtualTextWarn"  },
  [vim.diagnostic.severity.INFO]  = { sign = "DiagnosticSignInfo",  line = "DiagnosticVirtualTextInfo"  },
  [vim.diagnostic.severity.HINT]  = { sign = "DiagnosticSignHint",  line = "DiagnosticVirtualTextHint"  },
}

local function update_diag_linenum_hl(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then return end

  vim.api.nvim_buf_clear_namespace(bufnr, diag_ns, 0, -1)

  -- Track highest severity per line (lower value = higher severity)
  local line_severity = {}
  for _, diag in ipairs(vim.diagnostic.get(bufnr)) do
    local l = diag.lnum
    if not line_severity[l] or diag.severity < line_severity[l] then
      line_severity[l] = diag.severity
    end
  end

  for line, severity in pairs(line_severity) do
    local hl = severity_hl[severity]
    vim.api.nvim_buf_set_extmark(bufnr, diag_ns, line, 0, {
      number_hl_group = hl.sign,
      line_hl_group   = hl.line,
    })
  end
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
  group    = group,
  callback = function(ev) update_diag_linenum_hl(ev.buf) end,
})
