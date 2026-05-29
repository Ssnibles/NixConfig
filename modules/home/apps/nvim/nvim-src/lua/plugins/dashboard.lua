-- Dashboard: minimal, centred startup screen with composable sections.
-- Add, remove, or reorder entries in M.sections to customise the layout.
-- Each section is a function(dashboard) that returns { lines, highlights, keymaps }.
--   lines:       string array of content lines (centring is automatic).
--   highlights:  {{ line, col, end_line, end_col, group }, ...}  — all 0-indexed.
--   keymaps:     {{ key, cmd }, ...}  — buffer-local mappings.

local M = {}

-- ═══════════════════════════════════════════════════════════════
--  S E C T I O N   D E F I N I T I O N S
-- ═══════════════════════════════════════════════════════════════

--- ASCII banner (N E O V I M)
local function section_header()
	return {
		lines = {
			"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
			"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
			"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
			"██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║",
			"██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║",
			"╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝",
		},
		highlights = function(base)
			return {
				{
					line = base,
					end_line = base + 5,
					group = "AlphaHeader",
					full_line = true,
				},
			}
		end,
		keymaps = {},
	}
end

--- Quick-action shortcuts bar
--- Format: each entry is { key, label, command }
local function section_shortcuts()
	local entries = {
		{ "f", "Find file",  "<cmd>FzfLua files<CR>" },
		{ "r", "Recent",     "<cmd>FzfLua oldfiles<CR>" },
		{ "g", "Grep",       "<cmd>FzfLua live_grep<CR>" },
		{ "e", "Explorer",   "<cmd>Oil<CR>" },
		{ "q", "Quit",       "<cmd>qa<CR>" },
	}

	local parts = {}
	for _, e in ipairs(entries) do
		parts[#parts + 1] = e[1] .. "   " .. e[2]
	end
	local line = table.concat(parts, "       ")

	return {
		lines = { line },
		highlights = function(base)
			local hls = {}
			local col = 1
			for _, e in ipairs(entries) do
				local label = e[1] .. "   " .. e[2]
				local found = line:find(label, col, true)
				if found then
					hls[#hls + 1] = {
						line = base,
						col = found - 1,
						end_line = base,
						end_col = found - 1 + #label,
						group = "AlphaShortcut",
					}
				end
			end
			return hls
		end,
		keymaps = entries,
	}
end

--- Working-directory footer
local function section_footer()
	local cwd = vim.fn.getcwd():gsub(vim.env.HOME or "~", "~")
	return {
		lines = { cwd },
		highlights = function(base)
			return { {
				line = base,
				group = "AlphaFooter",
				full_line = true,
			} }
		end,
		keymaps = {},
	}
end

-- ═══════════════════════════════════════════════════════════════
--  S E C T I O N   R E G I S T R Y
--  Reorder / remove / insert sections here.
-- ═══════════════════════════════════════════════════════════════

M.sections = {
	section_header(),
	section_shortcuts(),
	section_footer(),
}

-- ═══════════════════════════════════════════════════════════════
--  R E N D E R I N G
-- ═══════════════════════════════════════════════════════════════

local function strwidth(s)
	return vim.fn.strdisplaywidth(s)
end

local function hpad(s, width)
	local sw = strwidth(s)
	local pad = math.floor((width - sw) / 2)
	if pad > 0 then
		return string.rep(" ", pad) .. s
	end
	return s
end

function M.open()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "dashboard://")
	vim.api.nvim_win_set_buf(0, buf)

	local width = vim.api.nvim_win_get_width(0)
	local height = vim.api.nvim_win_get_height(0)

	-- Collect all section output
	local body = {}
	local highlight_defs = {}
	local keymap_defs = {}
	local line_offset = 0

	for _, section in ipairs(M.sections) do
		if line_offset > 0 then
			body[#body + 1] = ""
			line_offset = line_offset + 1
		end

		local rel_base = line_offset
		for _, raw in ipairs(section.lines) do
			local padded = hpad(raw, width)
			body[#body + 1] = padded
			line_offset = line_offset + 1
		end

		local hls = section.highlights(rel_base)
		if hls then
			for _, h in ipairs(hls) do
				local center_line = h.line
				local raw_line = section.lines[center_line - rel_base + 1]
				local pad = math.floor((width - strwidth(raw_line)) / 2)
				if pad < 0 then
					pad = 0
				end

				local col = (h.col or 0) + pad
				local endc = h.end_col
				if endc == nil then
					endc = -1
				else
					endc = endc + pad
				end

				local end_line = h.end_line or h.line
				local end_body_idx = end_line < #body and (end_line + 1) or #body
				local end_line_len = #body[end_body_idx]

				if endc >= 0 and endc >= end_line_len then
					endc = -1
				end
				if col >= #body[center_line + 1] then
					col = 0
				end

				highlight_defs[#highlight_defs + 1] = {
					line = h.line,
					col = col,
					end_line = end_line,
					end_col = endc,
					group = h.group,
					priority = h.priority or 10,
				}
			end
		end

		for _, km in ipairs(section.keymaps) do
			keymap_defs[#keymap_defs + 1] = km
		end
	end

	-- Vertical centring
	local top_pad = math.floor((height - #body) / 2)
	if top_pad < 0 then
		top_pad = 0
	end

	local lines = {}
	for _ = 1, top_pad do
		lines[#lines + 1] = ""
	end
	vim.list_extend(lines, body)

	-- Shift highlights down by top_pad
	for _, h in ipairs(highlight_defs) do
		h.line = h.line + top_pad
		h.end_line = h.end_line + top_pad
	end

	-- Write buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "swapfile", false)
	vim.api.nvim_buf_set_option(buf, "modifiable", false)

	-- Window options
	local saved = {
		number = vim.wo.number,
		relativenumber = vim.wo.relativenumber,
		cursorline = vim.wo.cursorline,
		signcolumn = vim.wo.signcolumn,
		statuscolumn = vim.wo.statuscolumn,
	}
	vim.wo.number = false
	vim.wo.relativenumber = false
	vim.wo.cursorline = false
	vim.wo.signcolumn = "no"
	vim.wo.statuscolumn = ""
	vim.bo.filetype = "dashboard"

	local win = vim.api.nvim_get_current_win()
	local restore_group = vim.api.nvim_create_augroup("DashboardRestore", { clear = true })
	vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
		buffer = buf,
		group = restore_group,
		callback = function()
			vim.schedule(function()
				if not vim.api.nvim_win_is_valid(win) then
					pcall(vim.api.nvim_del_augroup_by_id, restore_group)
					return
				end
				vim.api.nvim_win_call(win, function()
					vim.wo.number = saved.number
					vim.wo.relativenumber = saved.relativenumber
					vim.wo.cursorline = saved.cursorline
					vim.wo.signcolumn = saved.signcolumn
					vim.wo.statuscolumn = saved.statuscolumn
				end)
				pcall(vim.api.nvim_del_augroup_by_id, restore_group)
			end)
		end,
	})

	-- Apply highlights
	local ns = vim.api.nvim_create_namespace("dashboard")
	local max_line = vim.api.nvim_buf_line_count(buf) - 1
	for _, h in ipairs(highlight_defs) do
		if h.line < 0 or h.line > max_line then
			goto continue
		end
		if h.end_line < 0 or h.end_line > max_line then
			h.end_line = max_line
		end
		local start_line_len = #vim.api.nvim_buf_get_lines(buf, h.line, h.line + 1, false)[1]
		local end_line_len = #vim.api.nvim_buf_get_lines(buf, h.end_line, h.end_line + 1, false)[1]
		if h.col < 0 or h.col > start_line_len then
			h.col = math.max(0, math.min(h.col, start_line_len))
		end
		if h.end_col < 0 or h.end_col > end_line_len then
			h.end_col = end_line_len
		end
		vim.api.nvim_buf_set_extmark(buf, ns, h.line, h.col, {
			hl_group = h.group,
			end_line = h.end_line,
			end_col = h.end_col,
			priority = h.priority or 10,
		})
		::continue::
	end

	-- Apply keymaps
	for _, km in ipairs(keymap_defs) do
		vim.keymap.set("n", km[1], km[3] or km[2], {
			buffer = buf,
			silent = true,
			nowait = true,
		})
	end
end

-- Open on empty startup
vim.api.nvim_create_autocmd("VimEnter", {
	group = vim.api.nvim_create_augroup("Dashboard", { clear = true }),
	once = true,
	callback = function()
		local show = vim.fn.argc() == 0
			and vim.fn.line2byte("$") == -1
			and vim.bo.filetype == ""
		if show then
			M.open()
		end
	end,
})

return M
