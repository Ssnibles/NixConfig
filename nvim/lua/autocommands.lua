local group = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- ── Yank highlight ────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TextYankPost", {
	group = group,
	callback = function()
		vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
	end,
})

-- ── Restore cursor position ───────────────────────────────────────────────
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- ── Trim trailing whitespace on save ─────────────────────────────────────
-- mini.trailspace highlights it; we call its trim() here for a clean API.
vim.api.nvim_create_autocmd("BufWritePre", {
	group = group,
	callback = function()
		local ok, ts = pcall(require, "mini.trailspace")
		if ok then
			ts.trim()
			ts.trim_last_lines()
		else
			-- Fallback: manual trim preserving cursor
			local pos = vim.api.nvim_win_get_cursor(0)
			vim.cmd([[%s/\s\+$//e]])
			vim.api.nvim_win_set_cursor(0, pos)
		end
	end,
})

-- ── Close certain buffers with q ──────────────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify", "oil" },
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true, desc = "Close window" })
	end,
})

-- ── Auto-resize splits when terminal is resized ───────────────────────────
vim.api.nvim_create_autocmd("VimResized", {
	group = group,
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- ── Strip ^M carriage returns on open ─────────────────────────────────────
vim.api.nvim_create_autocmd("BufReadPost", {
	group = group,
	callback = function()
		if vim.bo.fileformat == "dos" then
			vim.cmd([[silent! %s/\r//g]])
		end
	end,
})

-- ── Disable auto-comment continuation ────────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- ── Spell + wrap in prose filetypes ───────────────────────────────────────
vim.api.nvim_create_autocmd("FileType", {
	group = group,
	pattern = { "markdown", "text", "gitcommit" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
	end,
})

-- ── Diagnostic line-number highlights ─────────────────────────────────────
-- Tints the line number and background for every diagnostic line.
-- Colour groups are defined in plugins/completion.lua after the colorscheme.
local diag_ns = vim.api.nvim_create_namespace("diag_linenum_hl")

local severity_hl = {
	[vim.diagnostic.severity.ERROR] = { sign = "DiagnosticSignError", line = "DiagnosticLineError" },
	[vim.diagnostic.severity.WARN] = { sign = "DiagnosticSignWarn", line = "DiagnosticLineWarn" },
	[vim.diagnostic.severity.INFO] = { sign = "DiagnosticSignInfo", line = "DiagnosticLineInfo" },
	[vim.diagnostic.severity.HINT] = { sign = "DiagnosticSignHint", line = "DiagnosticLineHint" },
}

local function update_diag_hl(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, diag_ns, 0, -1)
	local worst = {}
	for _, d in ipairs(vim.diagnostic.get(bufnr)) do
		if not worst[d.lnum] or d.severity < worst[d.lnum] then
			worst[d.lnum] = d.severity
		end
	end
	for line, sev in pairs(worst) do
		local hl = severity_hl[sev]
		vim.api.nvim_buf_set_extmark(bufnr, diag_ns, line, 0, {
			number_hl_group = hl.sign,
			line_hl_group = hl.line,
		})
	end
end

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
	group = group,
	callback = function(ev)
		update_diag_hl(ev.buf)
	end,
})
