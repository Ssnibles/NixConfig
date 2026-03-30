-- =============================================================================
-- Neovim Entry Point
-- =============================================================================
-- This is the main initialization file. Load order matters:
--   1. Options     (basic vim settings, must come first)
--   2. Keymaps     (before plugins so plugins can override if needed)
--   3. Autocommands (event handlers)
--   4. Colorscheme  (before plugins for correct highlight inheritance)
--   5. Plugins      (in dependency order)
--
-- Version Requirement:
--   Neovim 0.11+ required for vim.lsp.config() and lsp.enable() APIs
-- =============================================================================

-- ── Version Check ──────────────────────────────────────────────────────────
-- Ensures Neovim version meets minimum requirements for LSP APIs
local version = vim.version()
if version.major < 0 or (version.major == 0 and version.minor < 11) then
	vim.notify("Neovim 0.11+ required. Found: " .. version.major .. "." .. version.minor, vim.log.levels.ERROR)
	return
end

-- ── Phase 1: Core Configuration ───────────────────────────────────────────
-- Load basic editor settings before any plugins
require("options")
-- Load keybindings before plugins (plugins may override)
require("keymaps")
-- Load event-driven behaviors
require("autocommands")

-- Configure diagnostics with consistent styling across all LSP clients
vim.diagnostic.config({
	-- Virtual text shows diagnostic messages inline
	virtual_text = { prefix = "●", spacing = 4 },
	-- Signs in the sign column for each severity
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "󰅚",
			[vim.diagnostic.severity.WARN] = "󰀪",
			[vim.diagnostic.severity.HINT] = "󰌶",
			[vim.diagnostic.severity.INFO] = "󰋽",
		},
	},
	-- Underline diagnostics in the buffer
	underline = true,
	-- Sort by severity (errors first)
	severity_sort = true,
	-- Float window styling
	float = { border = "none", source = true },
	-- Don't update diagnostics while typing (reduces noise in insert mode)
	update_in_insert = false,
})

-- ── Phase 2: Colorscheme & Highlights ─────────────────────────────────────
-- Load colorscheme before plugins so they inherit correct highlights
local function load_colorscheme()
	-- Try preferred schemes in order; fall back to built-in default
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
-- Apply custom highlight overrides
require("lib.highlights").apply()

-- ── Phase 3: Plugins (load in dependency order) ───────────────────────────
-- UI first: noice replaces the cmdline before statusline renders
-- gitsigns needs to attach before treesitter walks buffers
require("plugins.ui")
require("plugins.mini")
require("plugins.treesitter")
require("plugins.statusline")
require("plugins.completion")
require("plugins.lsp")
require("plugins.fzf")
require("plugins.conform")
require("plugins.neogit")
require("plugins.miscellaneous")

-- ── Phase 4: Final Configuration ──────────────────────────────────────────
-- cmdheight 0 defers to noice for all command-line output
vim.opt.cmdheight = 0

-- Health check accessible from anywhere with <leader>ch
vim.keymap.set("n", "<leader>ch", function()
	require("lib.health").check()
end, { desc = "Check configuration health" })
