-- LSP UI: the code outline (aerial) and peek windows (goto-preview).

require("aerial").setup({
	on_attach = function(bufnr)
		vim.keymap.set("n", "[a", "<cmd>AerialPrev<CR>", { buffer = bufnr, desc = "Previous symbol (Aerial)" })
		vim.keymap.set("n", "]a", "<cmd>AerialNext<CR>", { buffer = bufnr, desc = "Next symbol (Aerial)" })
	end,
	show_guides = true,
	layout = { max_width = { 40, 0.2 }, min_width = 30, default_direction = "prefer_right" },
	filter_kind = false,
	highlight_on_hover = true,
	autojump = false,
})

require("goto-preview").setup({
	references = { provider = "fzf_lua" },
})
