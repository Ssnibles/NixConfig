-- =============================================================================
-- Configuration Health Checks
-- =============================================================================
-- Runtime diagnostics for debugging configuration issues.
-- Run with :lua require("lib.health").check() or <leader>ch
-- =============================================================================

local M = {}

function M.check()
	local issues = {}
	local warnings = {}
	local info = {}

	-- ── Check Critical Plugins ─────────────────────────────────────────────
	-- These failing will cause visible breakage (no silent degradation)
	local critical = {
		"blink.cmp", -- completion
		"gitsigns", -- git signs, hunks, blame
		"oil", -- file navigation
		"noice", -- cmdline / notifications
	}
	for _, plugin in ipairs(critical) do
		if not pcall(require, plugin) then
			table.insert(issues, "[X] Missing: " .. plugin)
		else
			table.insert(info, "[OK] Loaded: " .. plugin)
		end
	end

	-- ── Check Non-critical Plugins ────────────────────────────────────────
	-- Missing these degrades the experience but nothing breaks outright
	local optional = {
		"fzf-lua",
		"lualine",
		"ibl",
		"conform",
		"nvim-treesitter",
		"copilot",
		"mini.ai",
	}
	for _, plugin in ipairs(optional) do
		if not pcall(require, plugin) then
			table.insert(warnings, "[!] Optional plugin unavailable: " .. plugin)
		end
	end

	-- ── Check Colorscheme ──────────────────────────────────────────────────
	if vim.g.colors_name ~= "vague" then
		table.insert(warnings, "[!] Colorscheme '" .. (vim.g.colors_name or "none") .. "' active (expected 'vague')")
	else
		table.insert(info, "[OK] Colorscheme: vague")
	end

	-- ── Check LSP Clients ──────────────────────────────────────────────────
	local clients = vim.lsp.get_clients()
	if #clients == 0 then
		table.insert(warnings, "[!] No LSP clients connected")
	else
		table.insert(info, "[OK] " .. #clients .. " LSP client(s) active")
	end

	-- ── Check Nix Flake Path ───────────────────────────────────────────────
	local flake_paths = {
		vim.env.NIX_CONFIG_FLAKE,
		vim.env.HOME .. "/NixConfig/flake.nix",
		vim.env.HOME .. "/nixos/flake.nix",
		vim.env.HOME .. "/.nixos/flake.nix",
	}
	local flake_found = false
	for _, path in ipairs(flake_paths) do
		if path and vim.fn.filereadable(path) == 1 then
			flake_found = true
			table.insert(info, "[OK] Flake found: " .. path)
			break
		end
	end
	if not flake_found then
		table.insert(warnings, "[!] No flake.nix found (nixd may not work optimally)")
	end

	-- ── Check Clipboard Provider ───────────────────────────────────────────
	if vim.fn.has("clipboard") == 0 then
		table.insert(warnings, "[!] Clipboard provider not available")
	else
		table.insert(info, "[OK] Clipboard provider available")
	end

	-- ── Report Results ─────────────────────────────────────────────────────
	-- Use vim.schedule so the notify calls fire after any in-flight LSP
	-- startup messages and show up cleanly in noice
	vim.schedule(function()
		if #issues > 0 then
			vim.notify("ISSUES:\n" .. table.concat(issues, "\n"), vim.log.levels.ERROR)
		end
		if #warnings > 0 then
			vim.notify("WARNINGS:\n" .. table.concat(warnings, "\n"), vim.log.levels.WARN)
		end
		if #info > 0 then
			vim.notify("INFO:\n" .. table.concat(info, "\n"), vim.log.levels.INFO)
		end
		if #issues == 0 and #warnings == 0 then
			vim.notify("[OK] Configuration healthy", vim.log.levels.INFO)
		end
	end)

	return #issues == 0, issues, warnings, info
end

return M
