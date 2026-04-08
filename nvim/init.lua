-- =============================================================================
-- Neovim Entry Point
-- =============================================================================
-- Zero-overhead initialization sequence:
--   1. Options      (basic editor settings)
--   2. Keymaps      (core keybindings)
--   3. Autocommands (event-based logic)
--   4. Diagnostics  (UI/UX configuration)
--   5. Colorscheme  (vague theme first)
--   6. Plugins      (modular configuration)
-- =============================================================================

-- ── Phase 1: Core Configuration ───────────────────────────────────────────
require("options")
require("keymaps")
require("autocommands")

-- Diagnostics configuration (refined for 0.11+)
vim.diagnostic.config({
	virtual_text = false,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚",
			[vim.diagnostic.severity.WARN] = "󰀪",
			[vim.diagnostic.severity.HINT] = "󰌶",
			[vim.diagnostic.severity.INFO] = "󰋽",
		},
	},
	underline = true,
	severity_sort = true,
	float = { border = "rounded", source = true },
	update_in_insert = false,
})

-- ── Phase 2: Theme & Highlights ───────────────────────────────────────────
-- Strictly prioritize 'vague' as the professional baseline
local ok_vague = pcall(vim.cmd.colorscheme, "vague")
if not ok_vague then
	pcall(vim.cmd.colorscheme, "default")
end
require("lib.highlights").apply()

-- ── Phase 3: Plugins (Direct Loading) ─────────────────────────────────────
-- Since plugins are managed via Nix (provided on the runtimepath), we simply
-- require their configuration modules. No heavy loader abstraction needed.

-- UI & Core Functional
require("plugins.ui") -- gitsigns, oil, noice, autopairs, markview
require("plugins.statusline") -- lualine, ibl, statuscol, neoscroll
require("plugins.mini") -- mini.nvim suite consolidation
require("plugins.treesitter") -- syntax highlighting

-- Development & Intelligence
require("plugins.completion") -- blink.cmp, copilot, luasnip
require("plugins.lsp") -- LSP configuration (0.11+ APIs)
require("plugins.conform") -- autoformatting
require("plugins.fzf") -- fuzzy finding
require("plugins.neogit") -- git interface

-- Miscellaneous
require("plugins.miscellaneous") -- leap, tmux-nav, grug-far

-- ── Phase 4: Final Polishing ──────────────────────────────────────────────
vim.opt.cmdheight = 0 -- Remove redundant visual chrome

-- Performance and health keymaps
vim.keymap.set("n", "<leader>ch", function()
	require("lib.health").check()
end, { desc = "Check configuration health" })

vim.keymap.set("n", "<leader>cl", function()
	local loader = require("lib.loader")
	local lines = { "# Plugin Load Times (ms)", "" }
	local sorted = {}
	for name, time in pairs(loader.stats.loaded) do
		table.insert(sorted, { name = name, time = time })
	end
	table.sort(sorted, function(a, b)
		return a.time > b.time
	end)
	for _, item in ipairs(sorted) do
		table.insert(lines, string.format("- %-30s : %.2f", item.name, item.time))
	end
	vim.api.nvim_echo({ { table.concat(lines, "\n"), "Normal" } }, true, {})
end, { desc = "Check plugin load times" })
