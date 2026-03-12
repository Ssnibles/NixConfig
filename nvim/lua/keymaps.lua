-- ============================================================================
-- KEYMAPS
-- ============================================================================

-- Convenience wrapper: all keymaps default to noremap + silent.
local function map(mode, lhs, rhs, desc)
	vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- ============================================================================
-- GENERAL
-- ============================================================================

-- Clear search highlight without moving the cursor.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search highlight")

-- ============================================================================
-- WINDOW MANAGEMENT
-- ============================================================================

map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")

-- ============================================================================
-- FILE NAVIGATION (Oil)
-- Oil lets you edit the filesystem like a buffer.
-- `-` mirrors the `-` binding in netrw for familiarity.
-- ============================================================================

map("n", "-", "<cmd>Oil<CR>", "Open Oil (parent dir)")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil (parent dir)")

-- ============================================================================
-- WINDOW NAVIGATION (smart-splits)
-- <C-hjkl> moves between splits using smart-splits if available,
-- falling back to plain wincmd if the plugin isn't loaded.
-- smart-splits also enables seamless navigation into tmux/wezterm panes.
-- ============================================================================

local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
	map("n", "<C-" .. key .. ">", function()
		local ok, ss = pcall(require, "smart-splits")
		if ok then
			ss["move_cursor_" .. dir]()
		else
			vim.cmd("wincmd " .. key)
		end
	end, "Move to " .. dir .. " window")
end
