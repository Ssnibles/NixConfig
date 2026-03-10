-- /home/josh/NixConfig/nvim/lua/plugins/conform.lua
local conform = require("conform")

conform.setup({
  formatters_by_ft = {
   lua = { "stylua" },
    python = { "isort", "black" },
    javascript = { "prettier" },
    nix = { "nixpkgs_fmt" },
  },
  -- This is the crucial part for automatic formatting on save
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
})

  -- Map for manual formatting
vim.keymap.set("n", "f", function()
  conform.format({ async = true, lsp_fallback = true })
end, { desc = "Format buffer" })
