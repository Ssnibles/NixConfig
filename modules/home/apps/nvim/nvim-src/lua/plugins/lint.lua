-- Linting: nvim-lint with Nix-focused diagnostics
local lint = require("lint")

local function parse_deadnix(output, bufnr)
	local ok, decoded = pcall(vim.json.decode, output)
	if not ok or type(decoded) ~= "table" or decoded.file == nil then
		return {}
	end

	local diagnostics = {}
	for _, item in ipairs(decoded.results or {}) do
		local line = math.max((item.line or 1) - 1, 0)
		local col = math.max((item.column or 1) - 1, 0)
		local end_col = math.max((item.endColumn or (col + 1)) - 1, col + 1)
		diagnostics[#diagnostics + 1] = {
			bufnr = bufnr,
			lnum = line,
			end_lnum = line,
			col = col,
			end_col = end_col,
			severity = vim.diagnostic.severity.WARN,
			source = "deadnix",
			message = item.message or "deadnix warning",
		}
	end

	return diagnostics
end

lint.linters.deadnix_nvim = {
	cmd = "deadnix",
	stdin = false,
	append_fname = true,
	args = { "-o", "json" },
	parser = parse_deadnix,
}

local function parse_statix_errfmt(output, bufnr)
	local diagnostics = {}
	for line in output:gmatch("[^\r\n]+") do
		local path, lnum, col, severity_letter, code, message =
			line:match("^([^>]+)>(%d+):(%d+):([WE]):(%d+):(.*)$")
		if path and message then
			local cur = vim.api.nvim_buf_get_name(bufnr)
			if vim.fn.fnamemodify(path, ":p") == vim.fn.fnamemodify(cur, ":p") then
				local line_num = math.max(tonumber(lnum) - 1, 0)
				local col_num = math.max(tonumber(col) - 1, 0)
				diagnostics[#diagnostics + 1] = {
					bufnr = bufnr,
					lnum = line_num,
					end_lnum = line_num,
					col = col_num,
					end_col = col_num + 1,
					severity = severity_letter == "E" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
					source = "statix",
					code = code,
					message = vim.trim(message),
				}
			end
		end
	end
	return diagnostics
end

lint.linters.statix_nvim = {
	cmd = "statix",
	stdin = false,
	append_fname = true,
	args = { "check", "--format", "errfmt" },
	parser = parse_statix_errfmt,
}

lint.linters_by_ft = {
	nix = { "deadnix_nvim", "statix_nvim" },
}

local lint_augroup = vim.api.nvim_create_augroup("UserLint", { clear = true })
local function run_lint()
	local ft = vim.bo.filetype
	if ft ~= "nix" then
		return
	end
	lint.try_lint()
end

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	group = lint_augroup,
	callback = run_lint,
})

vim.keymap.set("n", "<leader>cl", function()
	run_lint()
	vim.notify("Ran Nix linters (deadnix + statix)", vim.log.levels.INFO)
end, { desc = "Run linter" })
