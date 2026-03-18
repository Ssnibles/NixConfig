-- =============================================================================
-- Neovim Entry Point
-- =============================================================================
-- This is the main initialization file. Load order matters:
-- 1. Options (basic vim settings)
-- 2. Keymaps (before plugins so they can override)
-- 3. Autocommands (event handlers)
-- 4. Colorscheme (before plugins for highlight inheritance)
-- 5. Plugins (in dependency order)
-- =============================================================================

-- ── Version Check ──────────────────────────────────────────────────────────
-- Requires Neovim 0.10+ for stable LSP and treesitter APIs
local version = vim.version()
if version.major < 0 or (version.major == 0 and version.minor < 10) then
	vim.notify("Neovim 0.10+ required. Found: " .. version.major .. "." .. version.minor, vim.log.levels.ERROR)
	return
end

-- ── Phase 1: Core Configuration ───────────────────────────────────────────
require("options")
require("keymaps")
require("autocommands")

-- ── Phase 2: Colorscheme & Highlights ─────────────────────────────────────
local function load_colorscheme()
	local schemes = { "vague", "tokyonight", "gruvbox", "default" }
	for _, scheme in ipairs(schemes) do
		local ok = pcall(vim.cmd.colorscheme, scheme)
		if ok then
			vim.g.colors_name = scheme
			return scheme
		end
	end
	return "default"
end

load_colorscheme()
require("lib.highlights").apply()

-- ── Phase 3: Plugins (load in dependency order) ───────────────────────────
-- UI first (noice affects cmdline before statusline renders)
require("plugins.ui")
require("plugins.mini")
require("plugins.treesitter")
require("plugins.statusline")
require("plugins.completion")
require("plugins.lsp")
require("plugins.fzf")
require("plugins.conform")

-- ── Phase 4: Final Configuration ──────────────────────────────────────────
-- Enable noice cmdline replacement
vim.opt.cmdheight = 0

-- Configure diagnostics with consistent styling
vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
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

-- Add health check keymap
vim.keymap.set("n", "<leader>ch", function()
	require("lib.health").check()
end, { desc = "Check configuration health" })
