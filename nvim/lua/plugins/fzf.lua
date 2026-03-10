-- ============================================================================
-- FZF-LUA CONFIGURATION
-- ============================================================================
local fzf = require("fzf-lua")

fzf.setup({
  winopts = {
    backdrop = "NormalFloat", height = 0.95, width = 0.95, border = "rounded",
    preview = { layout = "vertical", vertical = "right:60%", scrollbar = true },
  },
  files = { cmd = "fd --type f --hidden --exclude .git --exclude node_modules" },
  grep = { rg_opts = "--color=never --hidden --glob '!{.git,node_modules}' --no-heading --line-number --column" },
})

vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Live grep" })
