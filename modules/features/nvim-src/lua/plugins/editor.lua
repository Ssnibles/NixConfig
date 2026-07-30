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

local formatters_by_ft = {
	lua = { "stylua" }, python = { "isort", "black" },
	javascript = { "prettierd" }, javascriptreact = { "prettierd" },
	typescript = { "prettierd" }, typescriptreact = { "prettierd" },
	css = { "prettierd" }, json = { "prettierd" }, yaml = { "prettierd" },
	markdown = { "prettierd" }, nix = { "nixfmt" }, sh = { "shfmt" },
	kotlin = { "ktlint" }, java = { "google-java-format" },
	cs = { "csharpier" }, rust = { "rustfmt" }, typst = { "typstyle" },
}

local function format_buffer()
	local bufnr = vim.api.nvim_get_current_buf()
	local ft = vim.bo[bufnr].filetype
	local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
	if #clients > 0 then
		vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 1000 })
		return
	end
	local formatters = formatters_by_ft[ft]
	if not formatters then
		vim.notify("No formatter configured for " .. ft, vim.log.levels.WARN)
		return
	end
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local text = table.concat(lines, "\n")
	for _, fmt in ipairs(formatters) do
		local result = vim.fn.systemlist({ fmt, "--stdin-filepath", vim.api.nvim_buf_get_name(bufnr) }, text)
		if vim.v.shell_error == 0 and #result > 0 then
			pcall(vim.api.nvim_buf_set_lines, bufnr, 0, -1, false, result)
			return
		end
	end
	vim.notify("Formatter failed for " .. ft, vim.log.levels.WARN)
end

vim.api.nvim_create_autocmd("BufWritePre", {
	callback = function()
		if vim.g.disable_autoformat then return end
		local ft = vim.bo.filetype
		if vim.g.disable_autoformat_ft[ft] then return end
		local bufnr = vim.api.nvim_get_current_buf()
		local clients = vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/formatting" })
		if #clients > 0 then
			pcall(vim.lsp.buf.format, { bufnr = bufnr, timeout_ms = 1000 })
		end
	end,
})

vim.keymap.set({ "n", "v" }, "<leader>cf", format_buffer, { desc = "Format buffer" })

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
