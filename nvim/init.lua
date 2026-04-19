-- Neovim configuration entry point

-- Core Lua config
require("keymaps")
require("autocmds")

-- Diagnostics
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

-- Theme
local ok_theme_meta, theme_meta = pcall(require, "generated.theme_meta")
if not ok_theme_meta or type(theme_meta) ~= "table" then
	theme_meta = { is_matugen = false }
end

if theme_meta.is_matugen then
	local ok_matugen, matugen = pcall(require, "matugen_colorscheme")
	local matugen_file = vim.fn.expand("~/.cache/matugen/colors.jsonc")
	if ok_matugen and vim.fn.filereadable(matugen_file) == 1 then
		matugen.setup({
			file = matugen_file,
			auto_apply = true,
			watch = false,
			plugins = {
				base = true,
				treesitter = true,
				cmp = true,
				gitsigns = true,
				miscellaneous = true,
			},
		})
	else
		require("theme").setup()
	end
else
	require("theme").setup()
end

local function safe_require(module)
	local ok, err = pcall(require, module)
	if not ok then
		vim.schedule(function()
			vim.notify(("Failed loading %s: %s"):format(module, err), vim.log.levels.ERROR)
		end)
	end
	return ok
end

-- Core plugins (load immediately)
for _, module in ipairs({
	"plugins.treesitter",
	"plugins.completion",
	"plugins.lsp",
	"plugins.editor",
	"plugins.lint",
	"plugins.ui",
	"plugins.trouble",
	"plugins.mini",
	"plugins.fzf",
	"plugins.navigation",
	"plugins.terminal",
}) do
	safe_require(module)
end

-- Optional plugins (defer until UI is ready)
vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		if vim.v.exiting ~= 0 then
			return
		end
		vim.schedule(function()
			for _, module in ipairs({ "plugins.focus", "plugins.neogit", "plugins.terminal", "plugins.dap" }) do
				safe_require(module)
			end
		end)
	end,
})

-- Final touches
vim.opt.cmdheight = 0
