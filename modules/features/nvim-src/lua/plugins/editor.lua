-- =============================================================================
-- Editor plugins: oil, gitsigns, grug-far, flash, smart-splits, sshinator
-- =============================================================================

-- ── Oil (file explorer) ──────────────────────────────────────────────

local function paste_image_to_oil()
	if vim.bo.filetype ~= "oil" then return end
	local targets = vim.fn.system("wl-paste --list-types")
	if not targets:match("image/png") then
		vim.notify("No PNG image in clipboard.", vim.log.levels.WARN)
		return
	end
	local oil = require("oil")
	local dir = oil.get_current_dir()
	if not dir then return end

	vim.ui.input({
		prompt = "Save clipboard image as: ",
		default = "image_" .. os.date("%Y%m%d_%H%M%S") .. ".png",
	}, function(input)
		if not input or input == "" then return end
		if not input:match("%.png$") then input = input .. ".png" end
		local result = vim.fn.system(("wl-paste -t image/png > %s"):format(vim.fn.shellescape(dir .. input)))
		if vim.v.shell_error == 0 then
			vim.notify("Saved image to " .. input)
			oil.open(dir)
		else
			vim.notify("Failed: " .. result, vim.log.levels.ERROR)
		end
	end)
end

vim.api.nvim_create_user_command("OilPasteImage", paste_image_to_oil, {})

require("oil").setup({
	columns = { "icon" },
	view_options = { show_hidden = true },
	float = { padding = 2, max_width = 0.8, max_height = 0.8, border = "rounded" },
	keymaps = {
		["<C-h>"] = false,
		["<M-h>"] = "actions.select_split",
		["<leader>p"] = { callback = paste_image_to_oil, desc = "Paste image from clipboard" },
	},
})

vim.keymap.set("n", "<leader>e", function()
	require("oil").toggle_float()
end, { desc = "Explorer (Oil)" })

-- ── Gitsigns ─────────────────────────────────────────────────────────

require("gitsigns").setup({
	signcolumn = true,
	numhl = true,
	current_line_blame = true,
	current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 800 },
	current_line_blame_formatter = function(name, info)
		if info.author == name then info.author = "You" end
		local days = math.floor((os.time() - info.author_time) / 86400)
		local when
		if days < 1 then when = "today"
		elseif days == 1 then when = "1 day ago"
		elseif days < 8 then when = days .. " days ago"
		else when = os.date("%d-%m-%Y", info.author_time) end
		return { { ("  %s, %s — %s"):format(info.author, when, info.summary), "GitSignsCurrentLineBlame" } }
	end,
	preview_config = { border = "rounded" },
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local map = function(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
		end
		map("n", "]g", gs.next_hunk, "Next hunk")
		map("n", "[g", gs.prev_hunk, "Prev hunk")
		map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
		map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
		map("n", "<leader>gu", gs.reset_hunk, "Unstage/reset hunk")
		map("n", "<leader>gb", gs.blame_line, "Blame line")
		map("n", "<leader>gD", gs.diffthis, "Diff this")
	end,
})

-- ── Grug-far (project-wide find & replace) ───────────────────────────

require("grug-far").setup()

-- Buffer-local find & replace helper
local function buffer_find_replace(default_search)
	vim.ui.input({ prompt = "Find in buffer: ", default = default_search or "" }, function(find)
		if not find or find == "" then return end
		vim.ui.input({ prompt = "Replace with: " }, function(replace)
			if replace == nil then return end
			local keys = (":<C-u>%%s/\\V%s/%s/g"):format(vim.fn.escape(find, "/"), vim.fn.escape(replace, "/&"))
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
		end)
	end)
end

vim.keymap.set("n", "<leader>fr", function()
	buffer_find_replace(vim.fn.expand("<cword>"))
end, { desc = "Find and replace (buffer)" })

vim.keymap.set("x", "<leader>fr", function()
	local old = vim.fn.getreg("z")
	local old_type = vim.fn.getregtype("z")
	vim.cmd([[noautocmd silent! normal! gv"zy]])
	local sel = (vim.fn.getreg("z"):match("^[^\r\n]*") or "")
	vim.fn.setreg("z", old, old_type)
	buffer_find_replace(sel)
end, { desc = "Find and replace selection (buffer)" })

-- ── Flash (jump motions) ─────────────────────────────────────────────

local flash = require("flash")

local excluded_ft = {
	fzf = true, oil = true, fugitive = true, ["grug-far"] = true, qf = true,
	help = true, jj = true, terminal = true,
}

local function is_main_editor(win)
	local w = win or vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(w)
	if vim.bo[buf].buftype ~= "" or excluded_ft[vim.bo[buf].filetype] then return false end
	return vim.api.nvim_win_get_config(w).relative == ""
end

flash.setup({
	search = {
		multi_window = true,
		exclude = { function(win) return not is_main_editor(win) end },
	},
})

vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", function()
	if is_main_editor() then flash.jump() end
end, { desc = "Flash jump" })
vim.keymap.set({ "n", "x", "o" }, "S", function()
	if is_main_editor() then flash.treesitter() end
end, { desc = "Flash treesitter" })

-- ── Smart-splits ─────────────────────────────────────────────────────

local splits = require("smart-splits")
splits.setup({})

vim.keymap.set("n", "<C-h>", splits.move_cursor_left, { desc = "Move left" })
vim.keymap.set("n", "<C-j>", splits.move_cursor_down, { desc = "Move down" })
vim.keymap.set("n", "<C-k>", splits.move_cursor_up, { desc = "Move up" })
vim.keymap.set("n", "<C-l>", splits.move_cursor_right, { desc = "Move right" })
vim.keymap.set("n", "<C-S-h>", splits.resize_left, { desc = "Resize left" })
vim.keymap.set("n", "<C-S-j>", splits.resize_down, { desc = "Resize down" })
vim.keymap.set("n", "<C-S-k>", splits.resize_up, { desc = "Resize up" })
vim.keymap.set("n", "<C-S-l>", splits.resize_right, { desc = "Resize right" })

-- ── Dev plugins (simple setups) ──────────────────────────────────────

local ok_ssh, sshinator = pcall(require, "sshinator")
if ok_ssh then
	sshinator.setup({ external_terminal = true, terminal_emulator = "foot" })
end

local ok_ind, indentinator = pcall(require, "indentinator")
if ok_ind then
	indentinator.setup({
		enabled = true,
		indent = { enabled = true, rainbow = { enabled = false } },
		scope = { treesitter = true },
	})
end

local ok_zl, zline = pcall(require, "zline")
if ok_zl then
	zline.setup({ use_icons = true, cmdline_prompt_bg = false, show = { spell = false } })
end

local ok_st, startinator = pcall(require, "startinator")
if ok_st then
	startinator.setup()
end

-- ── jj (Jujutsu) integration ────────────────────────────────────────

vim.keymap.set("n", "<leader>gg", function()
	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	local buf = vim.api.nvim_create_buf(false, true)
	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width, height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal", border = "rounded",
		title = " jjui ", title_pos = "center",
	})
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].cursorline = false
	vim.fn.termopen("jjui", {
		on_exit = function()
			if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
			if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
		end,
	})
	vim.cmd("startinsert")
end, { desc = "Open jjui (Jujutsu TUI)" })
