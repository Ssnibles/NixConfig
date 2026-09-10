local lint = require("lint")

-- ── Custom linter: deadnix ───────────────────────────────────────────

lint.linters.deadnix_nvim = {
	cmd = "deadnix",
	stdin = false,
	append_fname = true,
	args = { "-o", "json" },
	parser = function(output)
		local ok, decoded = pcall(vim.json.decode, output)
		if not ok or type(decoded) ~= "table" then return {} end
		local diagnostics = {}
		for _, entry in ipairs(decoded) do
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

-- ── Custom linter: statix ────────────────────────────────────────────

lint.linters.statix_nvim = {
	cmd = "statix",
	stdin = false,
	append_fname = true,
	args = { "check", "--format", "errfmt" },
	ignore_exitcode = true,
	parser = function(output, bufnr)
		local diagnostics = {}
		local cur = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":p")
		for line in output:gmatch("[^\r\n]+") do
			local path, lnum, col, sev, code, msg = line:match("^([^>]+)>(%d+):(%d+):([WE]):(%d+):(.*)$")
			if path and msg and vim.fn.fnamemodify(path, ":p") == cur then
				diagnostics[#diagnostics + 1] = {
					lnum = math.max(tonumber(lnum) - 1, 0),
					end_lnum = math.max(tonumber(lnum) - 1, 0),
					col = math.max(tonumber(col) - 1, 0),
					end_col = math.max(tonumber(col) - 1, 0) + 1,
					severity = sev == "E" and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
					source = "statix", code = code, message = vim.trim(msg),
				}
			end
		end
		return diagnostics
	end,
}

-- ── Linter assignments ───────────────────────────────────────────────

local filetypes = {
	nix = { "deadnix_nvim", "statix_nvim" },
	c = { "cppcheck" },
	cpp = { "cppcheck" },
}

lint.linters_by_ft = filetypes

-- ── Auto-lint on read/save ───────────────────────────────────────────

local function run_lint()
	if filetypes[vim.bo.filetype] then
		if vim.bo.modified and vim.api.nvim_buf_get_name(0) == "" then return end
		lint.try_lint()
	end
end

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
	group = vim.api.nvim_create_augroup("UserLint", { clear = true }),
	callback = run_lint,
})

vim.keymap.set("n", "<leader>cL", function()
	run_lint()
	vim.notify("Triggered linters for " .. vim.bo.filetype)
end, { desc = "Lint buffer" })
