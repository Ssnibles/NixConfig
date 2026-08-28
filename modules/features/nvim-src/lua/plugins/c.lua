-- =============================================================================
-- C & C++ CLANGD EXTENSIONS INTEGRATION
-- =============================================================================

local ok, clangd_ext = pcall(require, "clangd_extensions")
if ok then
	clangd_ext.setup({
		inlay_hints = {
			inline = vim.fn.has("nvim-0.10") == 1,
			only_current_line = false,
			only_current_line_autocmd = "CursorHold",
			show_parameter_hints = true,
			parameter_hints_prefix = "<- ",
			other_hints_prefix = "=> ",
			highlight = "Comment",
		},
		ast = {
			role_icons = {
				type = "🅉",
				declaration = "🄳",
				expression = "🄴",
				statement = "🅂",
				specifier = "🅂",
				["template argument"] = "🅃",
			},
			kind_icons = {
				Compound = "🄲",
				Recovery = "2",
				TranslationUnit = "🅄",
				PackExpansion = "🄿",
				TemplateTypeParm = "🅃",
				TemplateTemplateParm = "🅃",
				TemplateParamObject = "🅃",
			},
		},
		memory_usage = {
			border = "rounded",
		},
		symbol_info = {
			border = "rounded",
		},
	})
end

-- Generate compile_flags.txt for project (Raylib / Nix environment include paths)
local M = {}

--- Gathers and deduplicates C compiler include flags from the Nix environment & pkg-config
--- @return string[] List of compiler flags (e.g. { "-std=c11", "-Wall", "-Wextra", "-I/nix/store/...", ... })
function M.get_nix_c_flags()
	local flags = { "-std=c11", "-Wall", "-Wextra" }
	local seen = { ["-std=c11"] = true, ["-Wall"] = true, ["-Wextra"] = true }

	local function add_flag(flag)
		if flag and flag ~= "" and not seen[flag] then
			seen[flag] = true
			table.insert(flags, flag)
		end
	end

	-- 1. Parse CPATH, C_INCLUDE_PATH, CPLUS_INCLUDE_PATH (set by Nix shells / direnv)
	local cpath = (vim.env.CPATH or "")
		.. ":"
		.. (vim.env.C_INCLUDE_PATH or "")
		.. ":"
		.. (vim.env.CPLUS_INCLUDE_PATH or "")
	for path in cpath:gmatch("[^:]+") do
		if path ~= "" then
			add_flag("-I" .. path)
		end
	end

	-- 2. Parse NIX_CFLAGS_COMPILE (carries all devShell include paths automatically)
	local nix_cflags = vim.env.NIX_CFLAGS_COMPILE or ""
	for flag in nix_cflags:gmatch("%S+") do
		add_flag(flag)
	end

	-- 3. Query pkg-config for common C libraries if pkg-config is available
	if vim.fn.executable("pkg-config") == 1 then
		local pkgs = { "raylib", "wayland-client", "wlroots", "gl", "glfw3", "sdl2", "libxkbcommon", "libinput" }
		for _, pkg in ipairs(pkgs) do
			local handle = io.popen(("pkg-config --cflags %s 2>/dev/null"):format(pkg))
			if handle then
				local output = handle:read("*a")
				handle:close()
				for flag in output:gmatch("%S+") do
					add_flag(flag)
				end
			end
		end
	end

	return flags
end

vim.api.nvim_create_user_command("GenerateCompileFlags", function()
	local flags = M.get_nix_c_flags()
	local target_file = vim.fn.getcwd() .. "/compile_flags.txt"
	local file, err = io.open(target_file, "w")
	if not file then
		vim.notify("Failed to write compile_flags.txt: " .. tostring(err), vim.log.levels.ERROR)
		return
	end

	for _, flag in ipairs(flags) do
		file:write(flag .. "\n")
	end
	file:close()

	vim.notify("Generated compile_flags.txt in " .. vim.fn.getcwd(), vim.log.levels.INFO)
	pcall(vim.cmd, "LspRestart")
end, { desc = "Generate compile_flags.txt from environment & pkg-config" })

return M

