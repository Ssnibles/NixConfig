local function mode_str()
	local mode = vim.api.nvim_get_mode().mode
	-- Ctrl-V (block visual) is 0x16, Ctrl-S (block select) is 0x13
	if mode == "\x16" then mode = "V" elseif mode == "\x13" then mode = "S" end
	local mode_map = {
		n = "N", i = "I", v = "V", V = "V",
		c = "C", s = "S", S = "S",
		t = "T", R = "R", r = "R",
		["!"] = "!", rm = "R",
	}
	return " " .. (mode_map[mode] or "?") .. " "
end

local function git_info()
	local head = vim.b.gitsigns_head
	if not head then
		return ""
	end
	local status = vim.b.gitsigns_status
	if status and status ~= "" then
		return " " .. head .. status
	end
	return " " .. head
end

local function diagnostic_count()
	local count = vim.diagnostic.count(0)
	local parts = {}
	if count[vim.diagnostic.severity.ERROR] and count[vim.diagnostic.severity.ERROR] > 0 then
		table.insert(parts, "×" .. count[vim.diagnostic.severity.ERROR])
	end
	if count[vim.diagnostic.severity.WARN] and count[vim.diagnostic.severity.WARN] > 0 then
		table.insert(parts, "▲" .. count[vim.diagnostic.severity.WARN])
	end
	if #parts == 0 then
		return ""
	end
	return " " .. table.concat(parts, " ")
end

local function filename(avail_width)
	local name = vim.fn.expand("%:f")
	if name == "" then
		return " [No Name] "
	end
	local modified = vim.bo.modified and " +" or ""
	local readonly = vim.bo.readonly and " =" or ""
	local rel = vim.fn.expand("%:p:.")
	local file_width = vim.fn.strwidth(rel) + vim.fn.strwidth(modified) + vim.fn.strwidth(readonly)
	if file_width <= avail_width then
		return " " .. rel .. modified .. readonly .. " "
	end
	local parts = vim.split(rel, "/")
	local result = ""
	for i = #parts, 1, -1 do
		local candidate = parts[i] .. (result ~= "" and "/" or "") .. result
		local w = vim.fn.strwidth(" …/" .. candidate .. modified .. readonly)
		if w <= avail_width then
			result = candidate
		else
			break
		end
	end
	return " …/" .. result .. modified .. readonly .. " "
end

local function lsp_clients()
	local clients = vim.lsp.get_clients({ bufnr = 0 })
	if #clients == 0 then
		return ""
	end
	local names = {}
	for _, client in ipairs(clients) do
		table.insert(names, client.name)
	end
	return " " .. table.concat(names, ",") .. " "
end

local function filetype()
	local ft = vim.bo.filetype
	if ft == "" then
		return ""
	end
	return " " .. ft .. " "
end

local function line_info()
	return " " .. vim.fn.line(".") .. "/" .. vim.fn.line("$") .. " "
end

local function statusline()
	local mode_text = mode_str()
	local git_text = git_info()
	local diag_text = diagnostic_count()
	local lsp_text = lsp_clients()
	local ft_text = filetype()
	local pos_text = line_info()

	local right_str = lsp_text .. ft_text .. pos_text
	local right_width = vim.fn.strwidth(right_str)
	local left_fixed = mode_text .. git_text .. diag_text
	local left_fixed_width = vim.fn.strwidth(left_fixed)
	local avail = vim.fn.winwidth(0) - right_width - left_fixed_width - 1

	local file_text = filename(avail)

	local left = "%#StlMode#" .. mode_text .. "%*"
		.. "%#StlGit#" .. git_text .. "%*"
		.. "%#StlDiag#" .. diag_text .. "%*"
		.. "%#StlFile#" .. file_text .. "%*"
	local right = "%#StlLSP#" .. lsp_text .. "%*"
		.. "%#StlFT#" .. ft_text .. "%*"
		.. "%#StlPos#" .. pos_text .. "%*"
	return left .. "%=" .. right
end

vim.o.statusline = "%!v:lua.require('plugins.ui').statusline()"

local function statuscolumn()
	local foldcol = ""
	local signcol = "%s"
	local numcol = ""

	local foldcolumn = tonumber(vim.wo.foldcolumn) or 0
	if foldcolumn > 0 then
		local lnum = vim.v.lnum
		local foldclosed = vim.fn.foldclosed(lnum)
		local foldlevel = vim.fn.foldlevel(lnum)

		if foldclosed > 0 then
			foldcol = "▸"
		elseif foldlevel > 0 then
			foldcol = "▾"
		else
			foldcol = " "
		end
		foldcol = foldcol .. " "
	end

	local lnum = vim.v.lnum
	local lastlnum = tonumber(vim.fn.line("$")) or 1
	local width = #tostring(lastlnum)

	if vim.v.relnum == 0 then
		numcol = string.format("%" .. width .. "d ", lnum)
	else
		numcol = string.format("%" .. width .. "d ", vim.v.relnum)
	end

	return foldcol .. signcol .. numcol
end

vim.o.statuscolumn = "%!v:lua.require('plugins.ui').statuscolumn()"

local M = {}
M.statuscolumn = statuscolumn
M.statusline = statusline

return M
