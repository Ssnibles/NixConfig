-- Neogit: git interface

local neogit = require("neogit")
neogit.setup({
	disable_insert_on_commit = "auto",
	integrations = { fzf_lua = true },
	graph_style = "unicode",
})

vim.keymap.set("n", "<leader>gn", neogit.open, { desc = "Neogit" })
vim.keymap.set("n", "<leader>gg", neogit.open, { desc = "Neogit status" })
