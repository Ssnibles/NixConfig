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
	local critical = { "blink.cmp", "which-key", "gitsigns", "oil" }
	for _, plugin in ipairs(critical) do
		if not pcall(require, plugin) then
			table.insert(issues, "❌ Missing: " .. plugin)
		else
			table.insert(info, "✓ Loaded: " .. plugin)
		end
	end

	-- ── Check Colorscheme ──────────────────────────────────────────────────
	if vim.g.colors_name ~= "vague" then
		table.insert(warnings, "⚠️ Colorscheme '" .. (vim.g.colors_name or "none") .. "' active (expected 'vague')")
	end

	-- ── Check LSP Clients ──────────────────────────────────────────────────
	local clients = vim.lsp.get_clients()
	if #clients == 0 then
		table.insert(warnings, "⚠️ No LSP clients connected")
	else
		table.insert(info, "✓ " .. #clients .. " LSP client(s) active")
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
			table.insert(info, "✓ Flake found: " .. path)
			break
		end
	end
	if not flake_found then
		table.insert(warnings, "⚠️ No flake.nix found (nixd may not work optimally)")
	end

	-- ── Check Clipboard Provider ───────────────────────────────────────────
	if vim.fn.has("clipboard") == 0 then
		table.insert(warnings, "⚠️ Clipboard provider not available")
	else
		table.insert(info, "✓ Clipboard provider available")
	end

	-- ── Report Results ─────────────────────────────────────────────────────
	if #issues > 0 then
		vim.notify("ISSUES:\n" .. table.concat(issues, "\n"), vim.log.levels.ERROR)
	end
	if #warnings > 0 then
		vim.notify("WARNINGS:\n" .. table.concat(warnings, "\n"), vim.log.levels.WARN)
	end
	if #info > 0 then
		vim.notify("INFO:\n" .. table.concat(info, "\n"), vim.log.levels.INFO)
	end

	return #issues == 0, issues, warnings, info
end

return M
