-- Linting (nvim-lint): Nix and C/C++ linters, run on read and save.

local lint = require("lint")

local M = {}

lint.linters.deadnix_nvim = {
	cmd = "deadnix",
	stdin = false,
	append_fname = true,
	args = { "-o", "json" },
	parser = function(output)
		local ok, decoded = pcall(vim.json.decode, output)
		if not ok or type(decoded) ~= "table" then
			return {}
		end
		-- deadnix emits one object per file; older versions emitted an array.
		local entries = decoded.results and { decoded } or decoded
		local diagnostics = {}
		for _, entry in ipairs(entries) do
			for _, item in ipairs(entry.results or {}) do
				diagnostics[#diagnostics + 1] = {
					lnum = math.max((item.line or 1) - 1, 0),
					end_lnum = math.max((item.line or 1) - 1, 0),
					col = math.max((item.column or 1) - 1, 0),
					end_col = math.max((item.endColumn or item.column or 1) - 1, 1),
					severity = vim.diagnostic.severity.WARN,
					source = "deadnix",
					message = item.message or "Unused Nix code",
				}
			end
		end
		return diagnostics
	end,
}

lint.linters.statix_nvim = {
	cmd = "statix",
	stdin = false,
	append_fname = true,
	args = { "check", "--format", "errfmt" },
	ignore_exitcode = true,
	parser = function(output, bufnr)
		local diagnostics = {}
		local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
		for line in output:gmatch("[^\r\n]+") do
			local path, lnum, col, severity, code, message = line:match("^([^>]+)>(%d+):(%d+):([WE]):(%d+):(.*)$")
			if path and message and vim.fn.fnamemodify(path, ":p") == current then
				diagnostics[#diagnostics + 1] = {
					lnum = math.max(tonumber(lnum) - 1, 0),
					end_lnum = math.max(tonumber(lnum) - 1, 0),
					col = math.max(tonumber(col) - 1, 0),
					end_col = math.max(tonumber(col) - 1, 0) + 1,
					severity = severity == "E" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
					source = "statix",
					code = code,
					message = vim.trim(message),
				}
			end
		end
		return diagnostics
	end,
}

local linters_by_ft = {
	nix = { "deadnix_nvim", "statix_nvim" },
	c = { "cppcheck" },
	cpp = { "cppcheck" },
}

lint.linters_by_ft = linters_by_ft

--- Run the linters for the current buffer, if it has any.
function M.run()
	if not linters_by_ft[vim.bo.filetype] then
		return
	end
	if vim.bo.modified and vim.api.nvim_buf_get_name(0) == "" then
		return
	end
	lint.try_lint(nil, { ignore_errors = true })
end

function M.run_and_notify()
	M.run()
	vim.notify("Triggered linters for " .. vim.bo.filetype)
end

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
	group = vim.api.nvim_create_augroup("UserLint", { clear = true }),
	callback = M.run,
})

return M
