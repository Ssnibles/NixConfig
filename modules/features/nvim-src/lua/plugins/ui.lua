---@class StatuslineComponent
---@field render function(opts?: table): string|nil Function that returns formatted component text or nil if hidden
---@field hl function(): string Function returning the highlight group name for the component

--- Map Neovim raw mode strings to concise statusline display indicators.
--- Note: '\x16' is Ctrl-V (Visual Block) and '\x13' is Ctrl-S (Select Block).
---@type table<string, string>
local mode_map = {
	n = "N", i = "I", v = "V", V = "V",
	["\x16"] = "V", c = "C", s = "S", S = "S",
	["\x13"] = "S", t = "T", R = "R", r = "R",
	["!"] = "!", rm = "R",
}

--- Map Neovim raw mode strings directly to custom highlight groups.
---@type table<string, string>
local hl_map = {
	n = "StlModeN", i = "StlModeI", v = "StlModeV", V = "StlModeV",
	["\x16"] = "StlModeV", c = "StlModeC", s = "StlModeS", S = "StlModeS",
	["\x13"] = "StlModeS", t = "StlModeT", R = "StlModeR", r = "StlModeR",
	["!"] = "StlModeC", rm = "StlModeR",
}

--- Constructor helper for statusline components.
---@param render_fn fun(opts?: table): string|nil
---@param hl_fn fun(): string
---@return StatuslineComponent
local function component(render_fn, hl_fn)
	return { render = render_fn, hl = hl_fn }
end

--- Mode Indicator Component
--- Displays current editor mode and updates highlight accordingly.
local mode = component(
	function()
		local m = vim.api.nvim_get_mode().mode
		return " " .. (mode_map[m] or "?") .. " "
	end,
	function()
		local m = vim.api.nvim_get_mode().mode
		return hl_map[m] or "StlModeN"
	end
)

--- Git Status Component
--- Integrates directly with Gitsigns buffer variables (`vim.b.gitsigns_*`).
local git = component(
	function()
		local head = vim.b.gitsigns_head
		if not head or head == "" then return nil end
		local status = vim.b.gitsigns_status
		return "  " .. head .. (status and status ~= "" and (" " .. status) or "")
	end,
	function() return "StlGit" end
)

--- LSP Diagnostics Summary Component
--- Counts errors and warnings using native `vim.diagnostic.count`.
local diagnostics = component(
	function()
		local counts = vim.diagnostic.count(0)
		local err = counts[vim.diagnostic.severity.ERROR] or 0
		local warn = counts[vim.diagnostic.severity.WARN] or 0

		if err == 0 and warn == 0 then return nil end

		local parts = {}
		if err > 0 then table.insert(parts, "×" .. err) end
		if warn > 0 then table.insert(parts, "▲" .. warn) end
		return " " .. table.concat(parts, " ")
	end,
	function() return "StlDiag" end
)

--- Dynamic Filename Component
--- Dynamically truncates path segments right-to-left if width exceeds available budget.
---@class FilenameOpts
---@field avail integer Available horizontal character width allocated for the filename
---@field margin_right? integer Safety margin subtracted from available width

local filename = component(
	---@param opts FilenameOpts
	function(opts)
		local target = math.max(10, opts.avail - (opts.margin_right or 0))
		local bufname = vim.api.nvim_buf_get_name(0)

		if bufname == "" then return " [No Name] " end

		local modified = vim.bo.modified and " +" or ""
		local readonly = vim.bo.readonly and " =" or ""
		local suf = modified .. readonly

		-- Format absolute path to relative path using canonical forward slashes
		local rel = vim.fs.normalize(vim.fn.fnamemodify(bufname, ":."))
		
		-- Use full relative path if it fits within target width
		if vim.fn.strwidth(rel) + #suf <= target then
			return " " .. rel .. suf .. " "
		end

		-- Progressive truncation: reconstruct path backwards segment by segment
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

		-- Fallback to last segment (filename only) if even one parent folder doesn't fit
		return " …/" .. (result ~= "" and result or parts[#parts]) .. suf .. " "
	end,
	function() return "StlFile" end
)

--- Active LSP Clients Component
--- Lists attached language servers for current buffer.
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

--- Filetype Indicator Component
local filetype = component(
	function()
		local ft = vim.bo.filetype
		return (ft ~= "") and (" " .. ft .. " ") or nil
	end,
	function() return "StlFT" end
)

--- Cursor Position Component
--- Format: CurrentLine / TotalLines (e.g., 42/150)
local position = component(
	function()
		-- Fast C-API calls avoiding VimScript evaluation overhead
		local current_line = vim.api.nvim_win_get_cursor(0)[1]
		local total_lines = vim.api.nvim_buf_line_count(0)
		return " " .. current_line .. "/" .. total_lines .. " "
	end,
	function() return "StlPos" end
)

---@type StatuslineComponent[]
local left_bar = { mode, git, diagnostics }

---@type StatuslineComponent[]
local right_bar = { lsp, filetype, position }

--- Default options for filename formatting
local filename_opts = { margin_right = 6 }

--- Main Statusline Evaluation Function
--- Called by Neovim per window draw cycle via `%!v:lua...` string setting.
---@return string Statusline expression string
local function statusline()
	--- Evaluates a component group, constructing formatted statusline items and calculating visual width.
	---@param section StatuslineComponent[]
	---@return string formatted_str The concatenated statusline segment string
	---@return integer width Visual width in display cells
	local function collect(section)
		local items = {}
		local width = 0
		for _, c in ipairs(section) do
			local text = c.render()
			if text then
				local hl = c.hl()
				-- Embed highlight group switch (%#Group#) and highlight reset (%*) directly
				table.insert(items, "%#" .. hl .. "#" .. text .. "%*")
				width = width + vim.fn.strwidth(text)
			end
		end
		return table.concat(items), width
	end

	local left_str, left_width = collect(left_bar)
	local right_str, right_width = collect(right_bar)

	-- Calculate space remaining for filename component
	local non_filename = left_width + right_width
	local win_width = vim.api.nvim_win_get_width(0)
	
	-- Quantize available space down to steps of 5 for visually predictable truncation shifts
	local avail = math.max(10, math.floor((win_width - non_filename - 1) / 5) * 5)

	local file_opts = vim.tbl_extend("keep", { avail = avail }, filename_opts)
	local file_text = "%#StlFile#" .. filename.render(file_opts) .. "%*"

	-- %<: Truncate point if statusline overflows screen width
	-- %=: Right-align separation point
	return left_str .. "%<" .. file_text .. "%=" .. right_str
end

-- Global editor settings
vim.o.statusline = "%!v:lua.require('plugins.ui').statusline()"
vim.o.statuscolumn = "%C%s%=%{&relativenumber?(v:relnum?v:relnum:v:lnum):v:lnum} %#WinSeparator#▏%*"

return { statusline = statusline }
