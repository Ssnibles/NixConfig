-- =============================================================================
-- Neovim Initialization
-- =============================================================================
-- Load order is critical for proper plugin initialization and highlight
-- group inheritance. The colorscheme must load before any plugins that
-- define highlight overrides.

-- ── Version Check ──────────────────────────────────────────────────────────
local function check_version()
	local major, minor = vim.version().major, vim.version().minor
	if major < 0 or (major == 0 and minor < 11) then
		vim.notify(
			"This configuration requires Neovim 0.11 or higher. You are running " .. major .. "." .. minor,
			vim.log.levels.ERROR
		)
		return false
	end
	return true
end

if not check_version() then
	return
end

-- Phase 1: Core Vim options and keymaps (must load first)
require("options")
require("keymaps")
require("autocommands")

-- Phase 2: Colorscheme (before plugins so highlight overrides persist)
local function load_colorscheme()
	local schemes = { "vague", "tokyonight", "gruvbox", "default" }
	for _, scheme in ipairs(schemes) do
		if pcall(vim.cmd.colorscheme, scheme) then
			return scheme
		end
	end
	return "default"
end

load_colorscheme()

-- Phase 2.5: Apply centralized highlight overrides
require("lib.highlights").apply()

-- Phase 3: Plugin configuration
-- UI plugins load first (noice must load before statusline for cmdline)
require("plugins.ui")
require("plugins.mini")
require("plugins.treesitter")
require("plugins.statusline")
require("plugins.completion")
require("plugins.lsp")
require("plugins.fzf")
require("plugins.conform")

-- Phase 4: Final global configuration
-- Set cmdheight to 0 so noice can replace the cmdline area
vim.opt.cmdheight = 0

-- Configure diagnostic display with rounded floats and severity-sorted signs
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
