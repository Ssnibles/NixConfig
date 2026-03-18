-- lua/lib/health.lua
-- Configuration health checks for debugging
local M = {}

function M.check()
    local issues = {}
    local warnings = {}
    local info = {}

    -- Check critical plugins
    local critical = { "blink.cmp", "which-key", "gitsigns", "oil" }
    for _, plugin in ipairs(critical) do
        if not pcall(require, plugin) then
            table.insert(issues, string.format("❌ Missing: %s", plugin))
        else
            table.insert(info, string.format("✓ Loaded: %s", plugin))
        end
    end

    -- Check colorscheme
    if vim.g.colors_name ~= "vague" then
        table.insert(warnings, string.format("⚠️ Colorscheme '%s' active (expected 'vague')", vim.g.colors_name or "none"))
    end

    -- Check LSP clients
    local clients = vim.lsp.get_clients()
    if #clients == 0 then
        table.insert(warnings, "⚠️ No LSP clients connected")
    else
        table.insert(info, string.format("✓ %d LSP client(s) active", #clients))
    end

    -- Check Nix flake path for nixd
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
            table.insert(info, string.format("✓ Flake found: %s", path))
            break
        end
    end
    if not flake_found then
        table.insert(warnings, "⚠️ No flake.nix found (nixd may not work optimally)")
    end

    -- Check clipboard provider
    if vim.fn.has("clipboard") == 0 then
        table.insert(warnings, "⚠️ Clipboard provider not available")
    else
        table.insert(info, "✓ Clipboard provider available")
    end

    -- Report results
    if #issues > 0 then
        vim.notify("ISSUES:\n" .. table.concat(issues, "\n"), vim.log.levels.ERROR)
    end
    if #warnings > 0 then
        vim.notify("WARNINGS:\n" .. table.concat(warnings, "\n"), vim.log.levels.WARN)
    end
    if #info > 0 then
        vim.notify("INFO:\n" .. table.concat(info, "\n"), vim.log.levels.INFO)
    end

    -- Return overall status
    return #issues == 0, issues, warnings, info
end

return M
