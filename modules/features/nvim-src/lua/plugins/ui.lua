local function normalize_mode(mode)
	if mode == "\x16" then return "V" end
	if mode == "\x13" then return "S" end
	return mode
end

local mode_map = {
	n = "N", i = "I", v = "V", V = "V",
	c = "C", s = "S", S = "S",
	t = "T", R = "R", r = "R",
	["!"] = "!", rm = "R",
}

local hl_map = {
	n = "StlModeN", i = "StlModeI", v = "StlModeV", V = "StlModeV",
	c = "StlModeC", s = "StlModeS", S = "StlModeS",
	t = "StlModeT", R = "StlModeR", r = "StlModeR",
	["!"] = "StlModeC", rm = "StlModeR",
}

local current_mode = vim.api.nvim_get_mode().mode

local function update_mode()
	current_mode = vim.api.nvim_get_mode().mode
end

local update_group = vim.api.nvim_create_augroup("StatuslineMode", { clear = true })
vim.api.nvim_create_autocmd("ModeChanged", {
	group = update_group,
	pattern = "*:*",
	callback = update_mode,
})
vim.o.statusline = "%!v:lua.require('plugins.ui').statusline()"

local function component(render_fn, hl_fn)
	return { render = render_fn, hl = hl_fn }
end

local mode = component(
	function()
		return " " .. (mode_map[normalize_mode(current_mode)] or "?") .. " "
	end,
	function() return hl_map[normalize_mode(current_mode)] or "StlModeN" end
)

local git = component(
	function()
		local head = vim.b.gitsigns_head
		if not head then return nil end
		local status = vim.b.gitsigns_status
		return " " .. head .. (status or "")
	end,
	function() return "StlGit" end
)

local diagnostics = component(
	function()
		local count = vim.diagnostic.count(0)
		local parts = {}
		if count[vim.diagnostic.severity.ERROR] and count[vim.diagnostic.severity.ERROR] > 0 then
			table.insert(parts, "×" .. count[vim.diagnostic.severity.ERROR])
		end
		if count[vim.diagnostic.severity.WARN] and count[vim.diagnostic.severity.WARN] > 0 then
			table.insert(parts, "▲" .. count[vim.diagnostic.severity.WARN])
		end
		if #parts == 0 then return nil end
		return " " .. table.concat(parts, " ")
	end,
	function() return "StlDiag" end
)

local filename = component(
	function(opts)
		local avail = opts.avail
		local margin = opts.margin_right or 0
		local target = math.max(10, avail - margin)

		local name = vim.fn.expand("%:f")
		if name == "" then return " [No Name] " end
		local modified = vim.bo.modified and " +" or ""
		local readonly = vim.bo.readonly and " =" or ""
		local rel = vim.fn.expand("%:p:.")
		local suf = modified .. readonly
		if vim.fn.strwidth(rel) + vim.fn.strwidth(suf) <= target then
			return " " .. rel .. suf .. " "
		end
		local parts = vim.split(rel, "/")
		local result = ""
		for i = #parts, 1, -1 do
			local candidate = parts[i] .. (result ~= "" and "/" or "") .. result
			if vim.fn.strwidth(" …/" .. candidate .. suf) <= target then
				result = candidate
			else
				break
			end
		end
		return " …/" .. result .. suf .. " "
	end,
	function() return "StlFile" end
)

local lsp = component(
	function()
		local clients = vim.lsp.get_clients({ bufnr = 0 })
		if #clients == 0 then return nil end
		local names = {}
		for _, client in ipairs(clients) do
			table.insert(names, client.name)
		end
		return " " .. table.concat(names, ",") .. " "
	end,
	function() return "StlLSP" end
)

local filetype = component(
	function()
		local ft = vim.bo.filetype
		if ft == "" then return nil end
		return " " .. ft .. " "
	end,
	function() return "StlFT" end
)

local position = component(
	function()
		return " " .. vim.fn.line(".") .. "/" .. vim.fn.line("$") .. " "
	end,
	function() return "StlPos" end
)

local left_bar = { mode, git, diagnostics }
local right_bar = { lsp, filetype, position }

local filename_opts = { margin_right = 6 }

local function statusline()
	local function collect(section)
		local items = {}
		local width = 0
		for _, c in ipairs(section) do
			local text = c.render()
			if text then
				table.insert(items, { text = text, hl = c.hl() })
				width = width + vim.fn.strwidth(text)
			end
		end
		return items, width
	end

	local left_items, left_width = collect(left_bar)
	local right_items, right_width = collect(right_bar)

	local non_filename = left_width + right_width
	local avail = math.max(10, math.floor((vim.fn.winwidth(0) - non_filename - 1) / 5) * 5)

	local file_opts = vim.tbl_extend("keep", { avail = avail }, filename_opts)
	local file_text = "%#StlFile#" .. filename.render(file_opts) .. "%*"

	local function format(items)
		local parts = {}
		for _, item in ipairs(items) do
			table.insert(parts, "%#" .. item.hl .. "#" .. item.text .. "%*")
		end
		return table.concat(parts)
	end

	return format(left_items) .. "%<" .. file_text .. "%=" .. format(right_items)
end

vim.o.statuscolumn = "%C%s%=%{v:relnum?v:relnum:v:lnum} "

local M = {}
M.statusline = statusline

return M
