-- =============================================================================
-- Inline Diagnostics: Always-visible compact badges with hover expansion
-- =============================================================================
-- 1. All lines with diagnostics show compact virtual text with solid backgrounds.
-- 2. When hovering on an error line (CursorHold), it expands below into a full
--    card with column arrow (▲), tree branches (├─, ╰─), and word wrapping.
-- 3. On the active line, the EOL virtual text is hidden so Git blame (gitsigns)
--    never collides or pushes diagnostic text horizontally.
-- =============================================================================

local M = {}

local ns_compact = vim.api.nvim_create_namespace("user_diag_compact")
local ns_expanded = vim.api.nvim_create_namespace("user_diag_expanded")

local state = {
	enabled = true,
	buffers = {}, -- [bufnr] = { line_diags = {}, compact_marks = {}, expanded_lnum = nil }
	last_buf = nil,
	last_lnum = nil,
}

local SEVERITIES = {
	[vim.diagnostic.severity.ERROR] = {
		name = "Error",
		sign = "×",
		hl = "DiagnosticError",
		text_hl = "DiagnosticVirtualTextError",
	},
	[vim.diagnostic.severity.WARN] = {
		name = "Warn",
		sign = "▲",
		hl = "DiagnosticWarn",
		text_hl = "DiagnosticVirtualTextWarn",
	},
	[vim.diagnostic.severity.INFO] = {
		name = "Info",
		sign = "•",
		hl = "DiagnosticInfo",
		text_hl = "DiagnosticVirtualTextInfo",
	},
	[vim.diagnostic.severity.HINT] = {
		name = "Hint",
		sign = "•",
		hl = "DiagnosticHint",
		text_hl = "DiagnosticVirtualTextHint",
	},
}

local excluded_ft = {
	oil = true,
	["grug-far"] = true,
	fugitive = true,
	qf = true,
	help = true,
	fzf = true,
	terminal = true,
	ministarter = true,
	lazy = true,
}

--- Word-wrap a message into lines of at most max_len characters
--- @param text string
--- @param max_len number
--- @return string[]
local function wrap_text(text, max_len)
	local lines = {}
	for raw_line in text:gmatch("[^\r\n]+") do
		local words = vim.split(raw_line, "%s+", { trimempty = true })
		local cur = ""
		for _, word in ipairs(words) do
			if #cur == 0 then
				cur = word
			elseif #cur + 1 + #word <= max_len then
				cur = cur .. " " .. word
			else
				lines[#lines + 1] = cur
				cur = word
			end
		end
		if #cur > 0 then
			lines[#lines + 1] = cur
		end
	end
	return #lines > 0 and lines or { text }
end

--- Get or initialize buffer diagnostic state
--- @param bufnr number
--- @return table
local function get_buf_state(bufnr)
	if not state.buffers[bufnr] then
		state.buffers[bufnr] = {
			line_diags = {},
			compact_marks = {},
			expanded_lnum = nil,
		}
	end
	return state.buffers[bufnr]
end

--- Check if buffer should be processed for diagnostics
--- @param bufnr number
--- @return boolean
local function is_valid_buffer(bufnr)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return false
	end
	local bt = vim.bo[bufnr].buftype
	local ft = vim.bo[bufnr].filetype
	if bt ~= "" or excluded_ft[ft] then
		return false
	end
	if vim.diagnostic.is_enabled and not vim.diagnostic.is_enabled({ bufnr = bufnr }) then
		return false
	end
	return true
end

--- Render compact virtual text for a single line
--- @param bufnr number
--- @param lnum number
local function render_compact_line(bufnr, lnum)
	local bs = get_buf_state(bufnr)
	local diags = bs.line_diags[lnum]
	if not diags or #diags == 0 then
		return
	end

	-- Don't render compact if currently expanded on this line
	if bs.expanded_lnum == lnum then
		return
	end

	-- If already has a compact mark, remove old one first
	if bs.compact_marks[lnum] then
		pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_compact, bs.compact_marks[lnum])
		bs.compact_marks[lnum] = nil
	end

	local primary = diags[1]
	local info = SEVERITIES[primary.severity] or SEVERITIES[vim.diagnostic.severity.INFO]
	local more = #diags > 1 and (" (+" .. (#diags - 1) .. ")") or ""

	local msg = primary.message:gsub("[\r\n]+", " "):gsub("%s+", " ")
	if #msg > 60 then
		msg = msg:sub(1, 57) .. "…"
	end

	-- Solid background badge with icon and message
	local badge = "  " .. info.sign .. " " .. msg .. more .. " "

	local ok, mark_id = pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_compact, lnum, 0, {
		virt_text = { { badge, info.text_hl } },
		virt_text_pos = "eol",
		priority = 100,
	})
	if ok then
		bs.compact_marks[lnum] = mark_id
	end
end

--- Remove compact virtual text for a single line
--- @param bufnr number
--- @param lnum number
local function remove_compact_line(bufnr, lnum)
	local bs = get_buf_state(bufnr)
	if bs.compact_marks[lnum] then
		pcall(vim.api.nvim_buf_del_extmark, bufnr, ns_compact, bs.compact_marks[lnum])
		bs.compact_marks[lnum] = nil
	end
end

--- Expand diagnostics on the given line
--- @param bufnr number
--- @param lnum number
local function expand_line(bufnr, lnum)
	local bs = get_buf_state(bufnr)
	local diags = bs.line_diags[lnum]
	if not diags or #diags == 0 then
		return
	end

	-- Check if folded
	if vim.fn.foldclosed(lnum + 1) ~= -1 then
		return
	end

	-- Remove compact text from EOL so git blame has clean EOL space
	remove_compact_line(bufnr, lnum)

	-- Clear previous expanded extmark
	pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_expanded, 0, -1)
	bs.expanded_lnum = lnum

	local line_count = vim.api.nvim_buf_line_count(bufnr)
	if lnum < 0 or lnum >= line_count then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
	local line_text = lines[1] or ""

	local win = vim.api.nvim_get_current_win()
	local cur_col = vim.api.nvim_win_get_cursor(win)[2]

	-- Sort by severity, then proximity to cursor column
	table.sort(diags, function(a, b)
		if a.severity ~= b.severity then
			return a.severity < b.severity
		end
		local dist_a = math.abs((a.col or 0) - cur_col)
		local dist_b = math.abs((b.col or 0) - cur_col)
		return dist_a < dist_b
	end)

	local primary = diags[1]
	local primary_info = SEVERITIES[primary.severity] or SEVERITIES[vim.diagnostic.severity.INFO]

	local win_width = vim.api.nvim_win_get_width(win)
	local code_width = vim.fn.strdisplaywidth(line_text)
	local space_right = win_width - code_width - 6

	if space_right >= 32 then
		-- ── Expand on the right of the line (tiny-inline style) ───────────
		local arrow = "  "
		local max_msg_width = math.max(space_right - #arrow - 8, 24)
		local p_msg = primary.message:gsub("[\r\n]+", " "):gsub("%s+", " ")
		local wrapped = wrap_text(p_msg, max_msg_width)

		-- First line of diagnostic directly at EOL
		local virt_text = {
			{ arrow, primary_info.hl },
			{ " " .. primary_info.sign .. " " .. (wrapped[1] or "") .. " ", primary_info.text_hl },
		}
		if primary.source or primary.code then
			local badge = " [" .. (primary.source or "") .. (primary.code and (":" .. tostring(primary.code)) or "") .. "]"
			virt_text[#virt_text + 1] = { badge, "Comment" }
		end

		local virt_lines = {}
		local right_indent = string.rep(" ", code_width + #arrow)

		-- Continuation lines for wrapped message
		for w_idx = 2, #wrapped do
			table.insert(virt_lines, {
				{ right_indent .. "│ ", primary_info.hl },
				{ "   " .. wrapped[w_idx] .. " ", primary_info.text_hl },
			})
		end

		-- Additional diagnostics on the same line
		local count = math.min(#diags, 3)
		for idx = 2, count do
			local d = diags[idx]
			local info = SEVERITIES[d.severity] or SEVERITIES[vim.diagnostic.severity.INFO]
			local is_last = (idx == count)
			local connector = is_last and "╰─ " or "├─ "
			local d_msg = d.message:gsub("[\r\n]+", " "):gsub("%s+", " ")
			local d_wrapped = wrap_text(d_msg, max_msg_width)

			local row = {
				{ right_indent .. connector, info.hl },
				{ " " .. info.sign .. " " .. (d_wrapped[1] or "") .. " ", info.text_hl },
			}
			if d.source or d.code then
				local badge = " [" .. (d.source or "") .. (d.code and (":" .. tostring(d.code)) or "") .. "]"
				row[#row + 1] = { badge, "Comment" }
			end
			table.insert(virt_lines, row)

			local cont = is_last and "   " or "│  "
			for w_idx = 2, #d_wrapped do
				table.insert(virt_lines, {
					{ right_indent .. cont, info.hl },
					{ "   " .. d_wrapped[w_idx] .. " ", info.text_hl },
				})
			end
		end

		if #diags > count then
			table.insert(virt_lines, {
				{ right_indent .. "   ", "Comment" },
				{ ("… and %d more"):format(#diags - count), "Comment" },
			})
		end

		local extmark_opts = {
			virt_text = virt_text,
			virt_text_pos = "eol",
			priority = 200,
		}
		if #virt_lines > 0 then
			extmark_opts.virt_lines = virt_lines
			extmark_opts.virt_lines_above = false
		end

		pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_expanded, lnum, 0, extmark_opts)
	else
		-- ── Expand underneath (code is too wide to fit on the right) ──────
		local col = math.min(math.max(primary.col or 0, 0), #line_text)
		local visual_col = vim.fn.strdisplaywidth(line_text:sub(1, col))
		local code_indent = vim.fn.strdisplaywidth(line_text:match("^%s*") or "")
		local max_indent = math.max(win_width - 35, 2)
		local arrow_col = math.min(visual_col, max_indent)
		local box_indent = arrow_col <= 24 and arrow_col or code_indent
		local max_msg_width = math.max(win_width - box_indent - 16, 28)

		local virt_lines = {
			{ { string.rep(" ", arrow_col) .. "▲", primary_info.hl } },
		}

		local count = math.min(#diags, 3)
		for idx = 1, count do
			local d = diags[idx]
			local info = SEVERITIES[d.severity] or SEVERITIES[vim.diagnostic.severity.INFO]
			local is_last = (idx == count)
			local connector = is_last and "╰─ " or "├─ "
			local cont_prefix = is_last and "   " or "│  "

			local msg = d.message:gsub("[\r\n]+", " "):gsub("%s+", " ")
			local wrapped = wrap_text(msg, max_msg_width)

			local first_row = {
				{ string.rep(" ", box_indent) .. connector, info.hl },
				{ " " .. info.sign .. " " .. (wrapped[1] or "") .. " ", info.text_hl },
			}

			if d.source or d.code then
				local badge = " [" .. (d.source or "") .. (d.code and (":" .. tostring(d.code)) or "") .. "]"
				first_row[#first_row + 1] = { badge, "Comment" }
			end

			table.insert(virt_lines, first_row)

			for w_idx = 2, #wrapped do
				table.insert(virt_lines, {
					{ string.rep(" ", box_indent) .. cont_prefix .. "  ", info.hl },
					{ "   " .. wrapped[w_idx] .. " ", info.text_hl },
				})
			end
		end

		if #diags > count then
			table.insert(virt_lines, {
				{ string.rep(" ", box_indent) .. "    ", "Comment" },
				{ ("… and %d more"):format(#diags - count), "Comment" },
			})
		end

		pcall(vim.api.nvim_buf_set_extmark, bufnr, ns_expanded, lnum, 0, {
			virt_lines = virt_lines,
			virt_lines_above = false,
			priority = 200,
		})
	end
end

--- Collapse any expanded diagnostic in the buffer
--- @param bufnr number
local function collapse_expanded(bufnr)
	local bs = get_buf_state(bufnr)
	if bs.expanded_lnum ~= nil then
		local old_lnum = bs.expanded_lnum
		bs.expanded_lnum = nil
		pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_expanded, 0, -1)
		-- Restore compact view on that line
		render_compact_line(bufnr, old_lnum)
	end
end

--- Rebuild diagnostic index for a buffer and update compact marks
--- @param bufnr number
local function rebuild_buffer(bufnr)
	if not is_valid_buffer(bufnr) then
		M.clear(bufnr)
		return
	end

	local bs = get_buf_state(bufnr)
	pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_compact, 0, -1)
	pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_expanded, 0, -1)
	bs.compact_marks = {}
	bs.line_diags = {}
	bs.expanded_lnum = nil

	local all_diags = vim.diagnostic.get(bufnr)
	for _, d in ipairs(all_diags) do
		local l = d.lnum
		if not bs.line_diags[l] then
			bs.line_diags[l] = {}
		end
		table.insert(bs.line_diags[l], d)
	end

	-- Sort each line's diagnostics by severity
	for _, line_list in pairs(bs.line_diags) do
		table.sort(line_list, function(a, b)
			return a.severity < b.severity
		end)
	end

	local cur_win = vim.api.nvim_get_current_win()
	local cur_buf = vim.api.nvim_win_get_buf(cur_win)
	local cur_lnum = (cur_buf == bufnr) and (vim.api.nvim_win_get_cursor(cur_win)[1] - 1) or -1

	-- Render compact on all lines
	for lnum, _ in pairs(bs.line_diags) do
		render_compact_line(bufnr, lnum)
	end

	-- If cursor is currently resting on a diagnostic line, expand it
	if cur_lnum >= 0 and bs.line_diags[cur_lnum] then
		expand_line(bufnr, cur_lnum)
	end
end

--- Clear all extmarks across namespaces for a buffer
--- @param bufnr? number
function M.clear(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_is_valid(bufnr) then
		pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_compact, 0, -1)
		pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_expanded, 0, -1)
	end
	state.buffers[bufnr] = nil
	state.last_buf = nil
	state.last_lnum = nil
end

--- Expand diagnostic under current cursor position
function M.expand_current()
	if not state.enabled then
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	if not is_valid_buffer(bufnr) then
		return
	end
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local bs = get_buf_state(bufnr)

	if bs.line_diags[lnum] then
		expand_line(bufnr, lnum)
	end
end

--- Handle cursor movement: collapse old line, update state
local function on_cursor_moved()
	local bufnr = vim.api.nvim_get_current_buf()
	if not is_valid_buffer(bufnr) then
		return
	end

	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local bs = get_buf_state(bufnr)

	-- If cursor moved to a different line, collapse the previously expanded line
	if bs.expanded_lnum ~= nil and bs.expanded_lnum ~= lnum then
		collapse_expanded(bufnr)
	end

	state.last_buf = bufnr
	state.last_lnum = lnum
end

--- Toggle inline diagnostics on/off
function M.toggle()
	state.enabled = not state.enabled
	local bufnr = vim.api.nvim_get_current_buf()
	if not state.enabled then
		M.clear(bufnr)
	else
		rebuild_buffer(bufnr)
	end
	vim.notify("Inline diagnostics " .. (state.enabled and "enabled" or "disabled"))
end

--- Setup autocommands
function M.setup()
	local group = vim.api.nvim_create_augroup("UserInlineDiagnostics", { clear = true })

	-- Rebuild on buffer read or diagnostic change
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufEnter" }, {
		group = group,
		callback = function(ev)
			if is_valid_buffer(ev.buf) then
				rebuild_buffer(ev.buf)
			end
		end,
	})

	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = group,
		callback = function(ev)
			if is_valid_buffer(ev.buf) then
				rebuild_buffer(ev.buf)
			end
		end,
	})

	-- Fast collapse when moving to a different line
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = group,
		callback = on_cursor_moved,
	})

	-- Expand when pausing on an error line (CursorHold at updatetime)
	vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
		group = group,
		callback = function()
			M.expand_current()
		end,
	})

	-- Collapse in insert mode to keep typing unobstructed
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		callback = function()
			local bufnr = vim.api.nvim_get_current_buf()
			collapse_expanded(bufnr)
		end,
	})

	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		callback = function()
			M.expand_current()
		end,
	})

	-- Clean up memory on buffer wipeout
	vim.api.nvim_create_autocmd({ "BufWipeout", "BufDelete" }, {
		group = group,
		callback = function(ev)
			state.buffers[ev.buf] = nil
		end,
	})

	-- User command
	vim.api.nvim_create_user_command("InlineDiagnosticsToggle", M.toggle, {
		desc = "Toggle inline diagnostics",
	})
end

return M
