-- =============================================================================
-- Neovim Entry Point
-- =============================================================================
-- Load order matters:
--   1. Options     (basic vim settings)
--   2. Keymaps     (before plugins)
--   3. Autocommands (event handlers)
--   4. Colorscheme  (before plugins for highlight inheritance)
--   5. Plugins      (in dependency order)
-- =============================================================================

-- ── Version Check ──────────────────────────────────────────────────────────
local version = vim.version()
if version.major < 0 or (version.major == 0 and version.minor < 11) then
  vim.notify("Neovim 0.11+ required. Found: " .. version.major .. "." .. version.minor, vim.log.levels.ERROR)
  return
end

-- ── Phase 1: Core Configuration ───────────────────────────────────────────
require("options")
require("keymaps")
require("autocommands")

-- Diagnostics configuration
vim.diagnostic.config({
  virtual_text = { prefix = "●", spacing = 4 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚",
      [vim.diagnostic.severity.WARN] = "󰀪",
      [vim.diagnostic.severity.HINT] = "󰌶",
      [vim.diagnostic.severity.INFO] = "󰋽",
    },
  },
  underline = true,
  severity_sort = true,
  float = { border = "none", source = true },
  update_in_insert = false,
})

-- ── Phase 2: Colorscheme & Highlights ─────────────────────────────────────
local function load_colorscheme()
  local schemes = { "vague", "tokyonight", "gruvbox", "default" }
  for _, scheme in ipairs(schemes) do
    local ok = pcall(vim.cmd.colorscheme, scheme)
    if ok then
      vim.g.colors_name = scheme
      return scheme
    end
  end
  return "default"
end
load_colorscheme()
require("lib.highlights").apply()

-- ── Phase 3: Plugins (load in dependency order) ───────────────────────────
-- Note: We load plugins synchronously here. The 'VeryLazy' event is specific
-- to lazy.nvim and will not fire in this custom loader setup.

-- UI & Core
require("plugins.ui")       -- gitsigns, oil, noice, autopairs
require("plugins.mini")     -- mini suite (internally uses vim.schedule)
require("plugins.treesitter")

-- Functional
require("plugins.statusline") -- lualine, ibl, statuscol
require("plugins.completion") -- blink.cmp, copilot
require("plugins.lsp")        -- LSP config
require("plugins.fzf")        -- fzf-lua
require("plugins.conform")    -- formatter
require("plugins.neogit")     -- git UI
require("plugins.miscellaneous") -- leap, tmux-nav

-- ── Phase 4: Final Configuration ──────────────────────────────────────────
vim.opt.cmdheight = 0

vim.keymap.set("n", "<leader>ch", function()
  require("lib.health").check()
end, { desc = "Check configuration health" })
