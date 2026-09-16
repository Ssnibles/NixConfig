-- =============================================================================
-- Inline Diagnostics: Render rich diagnostics underneath the cursor line
-- =============================================================================
-- Displays diagnostics on virtual lines (virt_lines) directly under code.
-- Features:
--   - Arrow (▲) pointing to the exact column of the error
--   - Tree connectors (├─, ╰─) for multiple diagnostics on the same line
--   - Auto-wrapping long messages to fit window width
--   - Never collides with or shifts EOL virtual text (like git blame)
--   - Debounced on CursorHold with instant clear on line change
-- =============================================================================

local M = {}

local ns = vim.api.nvim_create_namespace("user_inline_diagnostics")

local state = {
	enabled = true,
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

--- Word-wrap text into lines of at most max_len characters
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

--- Clear all inline diagnostic extmarks
--- @param bufnr? number
function M.clear(bufnr)
	bufnr = bufnr or (state.last_buf and vim.api.nvim_buf_is_valid(state.last_buf) and state.last_buf) or vim.api.nvim_get_current_buf()
	if vim.api.nvim_buf_is_valid(bufnr) then
		pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
	end
	state.last_buf = nil
	state.last_lnum = nil
end

--- Render inline diagnostics on the current line
function M.render()
	if not state.enabled then
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	-- Skip utility / special buffers
	local bt = vim.bo[bufnr].buftype
	local ft = vim.bo[bufnr].filetype
	if bt ~= "" or excluded_ft[ft] then
		return
	end

	-- Check if diagnostics are globally or buffer-locally enabled
	if vim.diagnostic.is_enabled and not vim.diagnostic.is_enabled({ bufnr = bufnr }) then
		M.clear(bufnr)
		return
	end

	local win = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(win)
	local lnum = cursor[1] - 1
	local cur_col = cursor[2]

	-- Skip folded lines
	if vim.fn.foldclosed(lnum + 1) ~= -1 then
		M.clear(bufnr)
		return
	end

	-- Check buffer line bounds
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	if lnum < 0 or lnum >= line_count then
		return
	end

	-- Get line text
	local lines = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)
	local line_text = lines[1] or ""

	-- Fetch diagnostics on current line
	local diags = vim.diagnostic.get(bufnr, { lnum = lnum })
	if #diags == 0 then
		M.clear(bufnr)
		return
	end

	-- If on the same line and already rendered, skip redrawing
	if state.last_buf == bufnr and state.last_lnum == lnum then
		return
	end

	M.clear(bufnr)
	state.last_buf = bufnr
	state.last_lnum = lnum

	-- Sort diagnostics: highest severity first (1=ERROR, 2=WARN, etc.)
	table.sort(diags, function(a, b)
		if a.severity ~= b.severity then
			return a.severity < b.severity
		end
		-- Tie-break by proximity to current cursor column
		local dist_a = math.abs((a.col or 0) - cur_col)
		local dist_b = math.abs((b.col or 0) - cur_col)
		return dist_a < dist_b
	end)

	local primary = diags[1]
	local primary_info = SEVERITIES[primary.severity] or SEVERITIES[vim.diagnostic.severity.INFO]

	-- Calculate visual column of the primary diagnostic
	local col = math.min(math.max(primary.col or 0, 0), #line_text)
	local prefix = line_text:sub(1, col)
	local visual_col = vim.fn.strdisplaywidth(prefix)
	local code_indent = vim.fn.strdisplaywidth(line_text:match("^%s*") or "")

	-- Calculate window width bounds
	local win_width = vim.api.nvim_win_get_width(win)
	local max_indent = math.max(win_width - 35, 2)
	local arrow_col = math.min(visual_col, max_indent)

	-- Choose box indent: align with arrow if reasonably indented, otherwise snap to code indent
	local box_indent = arrow_col <= 24 and arrow_col or code_indent

	-- Max line width for message wrapping
	local max_msg_width = math.max(win_width - box_indent - 16, 28)

	local virt_lines = {}

	-- 1. Pointer arrow line pointing at the error column
	table.insert(virt_lines, {
		{ string.rep(" ", arrow_col) .. "▲", primary_info.hl },
	})

	-- 2. Diagnostic items (show up to 3 to keep view concise)
	local count = math.min(#diags, 3)
	for idx = 1, count do
		local d = diags[idx]
		local info = SEVERITIES[d.severity] or SEVERITIES[vim.diagnostic.severity.INFO]
		local is_last = (idx == count)
		local connector = is_last and "╰─ " or "├─ "
		local cont_prefix = is_last and "   " or "│  "

		local msg = d.message:gsub("\r", ""):gsub("\t", "  ")
		local wrapped = wrap_text(msg, max_msg_width)

		-- First line of diagnostic
		local first_row = {
			{ string.rep(" ", box_indent) .. connector, info.hl },
			{ info.sign .. " ", info.hl },
			{ wrapped[1] or "", "Normal" },
		}

		-- Source / code badge (e.g. [rust-analyzer:E0596])
		if d.source or d.code then
			local badge = " [" .. (d.source or "") .. (d.code and (":" .. tostring(d.code)) or "") .. "]"
			first_row[#first_row + 1] = { badge, "Comment" }
		end

		table.insert(virt_lines, first_row)

		-- Continuation lines if message was wrapped
		for w_idx = 2, #wrapped do
			table.insert(virt_lines, {
				{ string.rep(" ", box_indent) .. cont_prefix .. "  ", info.hl },
				{ wrapped[w_idx], "Normal" },
			})
		end
	end

	-- If there are more diagnostics than displayed, show count indicator
	if #diags > count then
		local remaining = #diags - count
		table.insert(virt_lines, {
			{ string.rep(" ", box_indent) .. "    ", "Comment" },
			{ ("… and %d more"):format(remaining), "Comment" },
		})
	end

	-- Place virtual lines directly below current line
	pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, lnum, 0, {
		virt_lines = virt_lines,
		virt_lines_above = false,
		priority = 200,
	})
end

--- Toggle inline diagnostics on/off
function M.toggle()
	state.enabled = not state.enabled
	if not state.enabled then
		M.clear()
	else
		M.render()
	end
	vim.notify("Inline diagnostics " .. (state.enabled and "enabled" or "disabled"))
end

--- Setup autocmds and user commands
function M.setup()
	local group = vim.api.nvim_create_augroup("UserInlineDiagnostics", { clear = true })

	-- Render on cursor pause
	vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
		group = group,
		callback = M.render,
	})

	-- Fast line change detection: clear when moving to a different line
	vim.api.nvim_create_autocmd("CursorMoved", {
		group = group,
		callback = function()
			if state.last_lnum ~= nil then
				local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
				if lnum ~= state.last_lnum then
					M.clear()
				end
			end
		end,
	})

	-- Clear on typing or leaving window/buffer
	vim.api.nvim_create_autocmd({ "InsertEnter", "BufLeave", "WinLeave" }, {
		group = group,
		callback = function()
			M.clear()
		end,
	})

	-- Re-render when diagnostics change on the active line
	vim.api.nvim_create_autocmd("DiagnosticChanged", {
		group = group,
		callback = function(ev)
			if state.last_buf == ev.buf then
				state.last_buf = nil
				state.last_lnum = nil
				M.render()
			end
		end,
	})

	-- User commands
	vim.api.nvim_create_user_command("InlineDiagnosticsToggle", M.toggle, {
		desc = "Toggle inline virtual line diagnostics",
	})
end

return M
