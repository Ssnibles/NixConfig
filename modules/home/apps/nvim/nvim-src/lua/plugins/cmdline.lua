local M = {}

local ns = vim.api.nvim_create_namespace("float_cmdline")
local buf, win
local state = { firstc = "", prompt = "", prefix_len = 0, visible = false, last_content = nil, last_input = "" }
local block_lines = {}

vim.opt.cmdheight = 0

local function is_win_valid()
	return win and vim.api.nvim_win_is_valid(win)
end

local function is_buf_valid()
	return buf and vim.api.nvim_buf_is_valid(buf)
end

local function get_or_create_buf()
	if is_buf_valid() then
		vim.bo[buf].modifiable = true
		return buf
	end
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_name(buf, "cmdline-float")
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.bo[buf].filetype = "cmdline"
	return buf
end

local function get_prefix()
	if state.firstc ~= "" then
		return state.firstc .. " "
	elseif state.prompt ~= "" then
		return state.prompt
	end
	return ""
end

local function apply_chunk_highlights(b, content, prefix_len, row_offset)
	row_offset = row_offset or 0
	local offset = prefix_len
	for _, chunk in ipairs(content or {}) do
		local hl_group, txt = chunk[1], chunk[2]
		if hl_group and hl_group ~= "" and #txt > 0 then
			pcall(vim.api.nvim_buf_set_extmark, b, ns, row_offset, offset, {
				end_col = offset + #txt,
				hl_group = hl_group,
				priority = 100,
			})
		end
		offset = offset + #txt
	end
end

local function apply_cursor(line, pos)
	local cursor_col = state.prefix_len + (pos or 0)
	if cursor_col < #line then
		pcall(vim.api.nvim_buf_set_extmark, buf, ns, 0, cursor_col, {
			end_col = cursor_col + 1,
			hl_group = "CmdlineCursor",
			priority = 200,
		})
	elseif #line > 0 then
		pcall(vim.api.nvim_buf_set_extmark, buf, ns, 0, #line - 1, {
			virt_text = { { " ", "CmdlineCursor" } },
			virt_text_pos = "overlay",
			priority = 200,
		})
	end
end

local function ensure_win(b, width, height)
	local cols = vim.o.columns
	if cols <= 0 then
		return
	end
	width = math.max(width, 40)
	width = math.min(width, math.floor(cols * 0.8))
	height = height or 1
	local col = math.floor((cols - width) / 2)
	local cfg = {
		relative = "editor",
		row = 0,
		col = col,
		width = width,
		height = height,
		style = "minimal",
		border = "rounded",
		zindex = 200,
	}
	if is_win_valid() then
		vim.api.nvim_win_set_config(win, cfg)
	else
		win = vim.api.nvim_open_win(b, false, cfg)
		vim.wo[win].winhighlight = "Normal:Normal,FloatBorder:FloatBorder"
	end
	vim.g.ui_cmdline_pos = { 2, col }
end

local function close_win()
	if is_win_valid() then
		vim.api.nvim_win_close(win, true)
	end
	win = nil
	vim.g.ui_cmdline_pos = nil
end

local function prepare_buf(content, pos)
	local b = get_or_create_buf()
	local prefix = get_prefix()
	state.prefix_len = #prefix
	state.last_content = content

	local parts = {}
	for _, chunk in ipairs(content or {}) do
		parts[#parts + 1] = chunk[2]
	end
	local input = table.concat(parts)
	state.last_input = input
	local display = prefix .. input
	if display == "" then
		display = " "
	end

	vim.api.nvim_buf_set_lines(b, 0, -1, false, { display })
	vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
	apply_chunk_highlights(b, content, #prefix)
	apply_cursor(display, pos)

	return b, #display + 6
end

local function update_cursor_buf(pos)
	if not is_buf_valid() then
		return
	end
	local prefix = get_prefix()
	local display = prefix .. state.last_input
	if display == "" then
		display = " "
	end

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { display })
	vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	apply_chunk_highlights(buf, state.last_content, state.prefix_len)
	apply_cursor(display, pos)
end

local function prepare_block(lines)
	local b = get_or_create_buf()
	local display_lines = {}
	for _, line in ipairs(lines) do
		local parts = {}
		for _, chunk in ipairs(line) do
			parts[#parts + 1] = chunk[2]
		end
		display_lines[#display_lines + 1] = table.concat(parts)
	end
	if #display_lines == 0 then
		display_lines = { " " }
	end

	vim.api.nvim_buf_set_lines(b, 0, -1, false, display_lines)
	vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)

	for row, line in ipairs(lines) do
		apply_chunk_highlights(b, line, 0, row - 1)
	end

	local max_width = 40
	for _, dl in ipairs(display_lines) do
		max_width = math.max(max_width, #dl + 2)
	end

	return b, max_width, #display_lines
end

local function schedule_open(b, width, height)
	vim.schedule(function()
		if not state.visible then
			return
		end
		pcall(ensure_win, b, width, height)
		vim.cmd("redraw")
	end)
end

local function schedule_close()
	vim.schedule(function()
		close_win()
	end)
end

vim.ui_attach(ns, { ext_cmdline = true }, function(event, ...)
	local args = { ... }

	if event == "cmdline_show" then
		local content, pos, firstc, prompt = args[1], args[2], args[3], args[4]
		state.firstc = firstc or ""
		state.prompt = prompt or ""
		state.visible = true
		local ok, b, width = pcall(prepare_buf, content, pos)
		if ok then
			schedule_open(b, width)
		end
	elseif event == "cmdline_pos" then
		if state.visible then
			pcall(update_cursor_buf, args[1])
		end
	elseif event == "cmdline_hide" then
		state.visible = false
		schedule_close()
	elseif event == "cmdline_block_show" then
		block_lines = {}
		for _, line in ipairs(args[1]) do
			block_lines[#block_lines + 1] = line
		end
		state.visible = true
		local ok, b, width, height = pcall(prepare_block, block_lines)
		if ok then
			schedule_open(b, width, height)
		end
	elseif event == "cmdline_block_append" then
		for _, line in ipairs(args[1]) do
			block_lines[#block_lines + 1] = line
		end
		if state.visible then
			local ok, b, width, height = pcall(prepare_block, block_lines)
			if ok then
				schedule_open(b, width, height)
			end
		end
	elseif event == "cmdline_block_hide" then
		block_lines = {}
		state.visible = false
		schedule_close()
	end

	return true
end)

return M
