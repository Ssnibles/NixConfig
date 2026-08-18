local flash = require("flash")

-- Only allow flash in "main editor" buffers: regular file buffers in a
-- non-floating window. Disables it in fzf-lua pickers, terminals, oil, etc.
local excluded_filetypes = {
	fzf = true,
	oil = true,
	fugitive = true,
	["grug-far"] = true,
	qf = true,
	help = true,
	NvimTree = true,
	["neo-tree"] = true,
	neogit = true,
	terminal = true,
	Trouble = true,
}

local function is_main_editor(win)
	local w = win or vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(w)
	if vim.bo[buf].buftype ~= "" then
		return false
	end
	if excluded_filetypes[vim.bo[buf].filetype] then
		return false
	end
	return vim.api.nvim_win_get_config(w).relative == ""
end

flash.setup({
	search = {
		multi_window = true,
		exclude = {
			function(win)
				return not is_main_editor(win)
			end,
		},
	},
})

local function flash_jump()
	if not is_main_editor() then return end
	flash.jump()
end

local function flash_treesitter()
	if not is_main_editor() then return end
	flash.treesitter()
end

vim.keymap.set({ "n", "x", "o" }, "<leader><leader>", flash_jump, { desc = "Flash jump" })
vim.keymap.set({ "n", "x", "o" }, "S", flash_treesitter, { desc = "Flash treesitter" })

require("grug-far").setup()
vim.keymap.set("n", "<leader>fR", "<cmd>GrugFar<CR>", { desc = "Find and replace (project)" })

local function buffer_find_replace(default_search)
	vim.ui.input({ prompt = "Find in buffer: ", default = default_search or "" }, function(find)
		if not find or find == "" then return end
		vim.ui.input({ prompt = "Replace with: " }, function(replace)
			if replace == nil then return end
			local escaped_find = vim.fn.escape(find, "/")
			local escaped_replace = vim.fn.escape(replace, "/&")
			local keys = string.format(":<C-u>%%s/\\V%s/%s/g", escaped_find, escaped_replace)
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
		end)
	end)
end

vim.keymap.set("n", "<leader>fr", function()
	buffer_find_replace(vim.fn.expand("<cword>"))
end, { desc = "Find and replace (buffer)" })

vim.keymap.set("x", "<leader>fr", function()
	local old_reg = vim.fn.getreg("z")
	local old_regtype = vim.fn.getregtype("z")
	vim.cmd([[noautocmd silent! normal! gv"zy]])
	local selection = vim.fn.getreg("z")
	vim.fn.setreg("z", old_reg, old_regtype)
	selection = selection:match("^[^\r\n]*") or ""
	buffer_find_replace(selection)
end, { desc = "Find and replace selection (buffer)" })

local smart_splits = require("smart-splits")
smart_splits.setup({})

local map = vim.keymap.set
map("n", "<C-h>", smart_splits.move_cursor_left, { desc = "Move left" })
map("n", "<C-j>", smart_splits.move_cursor_down, { desc = "Move down" })
map("n", "<C-k>", smart_splits.move_cursor_up, { desc = "Move up" })
map("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Move right" })
map("n", "<C-S-h>", smart_splits.resize_left, { desc = "Resize split left" })
map("n", "<C-S-j>", smart_splits.resize_down, { desc = "Resize split down" })
map("n", "<C-S-k>", smart_splits.resize_up, { desc = "Resize split up" })
map("n", "<C-S-l>", smart_splits.resize_right, { desc = "Resize split right" })
