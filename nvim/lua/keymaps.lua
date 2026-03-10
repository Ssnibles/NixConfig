-- ============================================================================
-- KEYMAP UTILITIES & DEFINITIONS
-- ============================================================================
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

-- Navigation & UI
map("n", "<Esc>", "<cmd>nohlsearch<CR>", "Clear search")
map("n", "<leader>wv", "<C-w>v", "Split vertical")
map("n", "<leader>wh", "<C-w>s", "Split horizontal")
map("n", "<leader>wx", "<C-w>c", "Close window")
map("n", "-", "<cmd>Oil<CR>", "Open Oil")
map("n", "<leader>o", "<cmd>Oil<CR>", "Open Oil")
map("n", "n", "%")

-- Window navigation with smart-splits fallback
local dirs = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(dirs) do
  map("n", "<C-" .. key .. ">", function()
    local ok, ss = pcall(require, "smart-splits")
    if ok then
      ss["move_cursor_" .. dir]()
    else
      vim.cmd("wincmd " .. key)
    end
  end, "Move " .. dir)
end
