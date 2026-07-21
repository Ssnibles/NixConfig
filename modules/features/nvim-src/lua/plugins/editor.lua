require("oil").setup({
	columns = { "icon" },
	view_options = { show_hidden = true },
	float = { padding = 2, max_width = 0.8, max_height = 0.8, border = "rounded" },
	keymaps = {
		["<C-h>"] = false,
		["<M-h>"] = "actions.select_split",
	},
})

vim.keymap.set("n", "<leader>e", function() require("oil").toggle_float() end, { desc = "Explorer (Oil)" })

require("gitsigns").setup({
	signcolumn = true, numhl = true, linehl = false, word_diff = false,
	current_line_blame = true,
	current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 800, ignore_whitespace = false },
	current_line_blame_formatter = function(name, blame_info)
		if blame_info.author == name then blame_info.author = "You" end
		local now = os.time()
		local diff = now - blame_info.author_time
		local days = math.floor(diff / 86400)
		local time_str
		if days < 1 then time_str = "today"
		elseif days == 1 then time_str = "1 day ago"
		elseif days < 8 then time_str = days .. " days ago"
		else time_str = os.date("%d-%m-%Y", blame_info.author_time) end
		return { { string.format("  %s, %s — %s", blame_info.author, time_str, blame_info.summary), "GitSignsCurrentLineBlame" } }
	end,
	preview_config = { border = "rounded" },
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local map = function(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc }) end
		map("n", "]g", gs.next_hunk, "Next hunk")
		map("n", "[g", gs.prev_hunk, "Prev hunk")
		map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
		map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
		map("n", "<leader>gu", gs.reset_hunk, "Unstage/reset hunk")
		map("n", "<leader>gb", gs.blame_line, "Blame line")
		map("n", "<leader>gD", gs.diffthis, "Diff this")
	end,
})

vim.g.disable_autoformat = vim.g.disable_autoformat or false
vim.g.disable_autoformat_ft = vim.g.disable_autoformat_ft or { c = true, cpp = true }

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" }, python = { "isort", "black" },
		javascript = { "prettier" }, javascriptreact = { "prettier" },
		typescript = { "prettier" }, typescriptreact = { "prettier" },
		css = { "prettier" }, json = { "prettier" }, yaml = { "prettier" },
		markdown = { "prettier" }, nix = { "nixfmt" }, sh = { "shfmt" },
		kotlin = { "ktlint" }, java = { "google-java-format" },
		cs = { "csharpier" }, rust = { "rustfmt" }, typst = { "typstyle" },
	},
	format_on_save = function(bufnr)
		if vim.g.disable_autoformat then return nil end
		local ft = vim.bo[bufnr].filetype
		if vim.g.disable_autoformat_ft[ft] then return nil end
		return { timeout_ms = 1000, lsp_format = "fallback" }
	end,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
	require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format buffer" })

vim.keymap.set("n", "<leader>tF", function()
	vim.g.disable_autoformat = not vim.g.disable_autoformat
	local msg = vim.g.disable_autoformat and "disabled" or "enabled"
	vim.notify(("Autoformat %s"):format(msg), vim.log.levels.INFO)
end, { desc = "Toggle autoformat (global)" })

vim.keymap.set("n", "<leader>tA", function()
	local ft = vim.bo.filetype
	if ft == "" then return end
	vim.g.disable_autoformat_ft[ft] = not vim.g.disable_autoformat_ft[ft]
	local msg = vim.g.disable_autoformat_ft[ft] and "disabled" or "enabled"
	vim.notify(("Autoformat for %s %s"):format(ft, msg), vim.log.levels.INFO)
end, { desc = "Toggle autoformat for filetype" })

local augend = require("dial.augend")
require("dial.config").augends:register_group({
	default = {
		augend.integer.alias.decimal, augend.integer.alias.hex,
		augend.date.alias["%Y/%m/%d"], augend.date.alias["%Y-%m-%d"],
		augend.constant.alias.bool, augend.constant.alias.alpha, augend.constant.alias.Alpha,
	},
})

local dial_map = require("dial.map")
vim.keymap.set("n", "<C-a>", dial_map.inc_normal(), { desc = "Increment" })
vim.keymap.set("n", "<C-x>", dial_map.dec_normal(), { desc = "Decrement" })
vim.keymap.set("v", "<C-a>", dial_map.inc_visual(), { desc = "Increment selection" })
vim.keymap.set("v", "<C-x>", dial_map.dec_visual(), { desc = "Decrement selection" })
vim.keymap.set("n", "g<C-a>", dial_map.inc_gnormal(), { desc = "Increment (g)" })
vim.keymap.set("n", "g<C-x>", dial_map.dec_gnormal(), { desc = "Decrement (g)" })
vim.keymap.set("v", "g<C-a>", dial_map.inc_gvisual(), { desc = "Increment selection (g)" })
vim.keymap.set("v", "g<C-x>", dial_map.dec_gvisual(), { desc = "Decrement selection (g)" })
