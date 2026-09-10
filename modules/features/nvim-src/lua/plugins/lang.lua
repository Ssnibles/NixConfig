-- =============================================================================
-- Language-specific configurations: Rust, C/C++
-- =============================================================================
-- Previously separate rust.lua and c.lua files, now consolidated since both
-- are filetype-deferred language support modules.
-- =============================================================================

local M = {}

-- ── Rust (rustaceanvim) ──────────────────────────────────────────────

local function first_executable(commands)
	for _, cmd in ipairs(commands) do
		if vim.fn.executable(cmd) == 1 then return vim.fn.exepath(cmd) end
	end
	return nil
end

vim.g.rustaceanvim = {
	server = {
		settings = function(project_root, default_settings)
			local has_cargo = project_root and vim.uv.fs_stat(vim.fs.joinpath(project_root, "Cargo.toml")) ~= nil
			local ra = {
				["rust-analyzer"] = {
					cargo = { allFeatures = true },
					procMacro = { enable = true },
					completion = { autoimport = { enable = true } },
					checkOnSave = has_cargo,
				},
			}
			if has_cargo then
				ra["rust-analyzer"].check = { command = "clippy" }
			end
			return vim.tbl_deep_extend("force", default_settings, ra)
		end,
	},
	dap = {
		adapter = function()
			local codelldb = first_executable({ "codelldb", "lldb-dap", "lldb-vscode" })
			if not codelldb then return false end
			if codelldb:match("codelldb$") then
				return { type = "server", port = "${port}", host = "127.0.0.1", executable = { command = codelldb, args = { "--port", "${port}" } } }
			end
			return { type = "executable", command = codelldb, name = "lldb" }
		end,
	},
}

local function rustlsp(...)
	if vim.fn.exists(":RustLsp") == 2 then vim.cmd.RustLsp(...) end
end

local map = vim.keymap.set
map("n", "<leader>rr", function() rustlsp("runnables") end, { desc = "Rust runnables" })
map("n", "<leader>rt", function() rustlsp({ "testables", { background = true } }) end, { desc = "Rust testables" })
map("n", "<leader>rm", function() rustlsp("expandMacro") end, { desc = "Rust expand macro" })
map("n", "<leader>ro", function() rustlsp("openDocs") end, { desc = "Rust open docs" })
map("n", "<leader>rp", function() rustlsp("parentModule") end, { desc = "Rust parent module" })
map("n", "<leader>rH", function() rustlsp("reloadWorkspace") end, { desc = "Rust reload workspace" })
map("n", "<leader>re", function() rustlsp("rebuildMacros") end, { desc = "Rust rebuild macros" })
map({ "n", "v" }, "<leader>ra", function() rustlsp("codeAction") end, { desc = "Rust code action" })
map("n", "<leader>rs", function()
	local ok, clients = pcall(vim.lsp.get_clients, { name = "rust-analyzer", bufnr = 0 })
	if ok and #clients > 0 then vim.lsp.stop_client(clients) end
	rustlsp("reloadWorkspace")
end, { desc = "Rust restart server" })

-- ── C / C++ (clangd extensions) ──────────────────────────────────────

local ok_ext, clangd_ext = pcall(require, "clangd_extensions")
if ok_ext then
	clangd_ext.setup({
		inlay_hints = {
			inline = vim.fn.has("nvim-0.10") == 1,
			show_parameter_hints = true,
			parameter_hints_prefix = "<- ",
			other_hints_prefix = "=> ",
			highlight = "Comment",
		},
		ast = {
			role_icons = { type = "🅉", declaration = "🄳", expression = "🄴", statement = "🅂", specifier = "🅂", ["template argument"] = "🅃" },
			kind_icons = { Compound = "🄲", Recovery = "2", TranslationUnit = "🅄", PackExpansion = "🄿", TemplateTypeParm = "🅃", TemplateTemplateParm = "🅃", TemplateParamObject = "🅃" },
		},
		memory_usage = { border = "rounded" },
		symbol_info = { border = "rounded" },
	})
end

--- Gathers C compiler include flags from the Nix environment & pkg-config
--- @return string[]
function M.get_nix_c_flags()
	local flags = { "-std=c11", "-Wall", "-Wextra" }
	local seen = { ["-std=c11"] = true, ["-Wall"] = true, ["-Wextra"] = true }

	local function add(flag)
		if flag and flag ~= "" and not seen[flag] then
			seen[flag] = true
			flags[#flags + 1] = flag
		end
	end

	-- Nix include paths
	local cpath = (vim.env.CPATH or "") .. ":" .. (vim.env.C_INCLUDE_PATH or "") .. ":" .. (vim.env.CPLUS_INCLUDE_PATH or "")
	for path in cpath:gmatch("[^:]+") do
		if path ~= "" then add("-I" .. path) end
	end

	-- NIX_CFLAGS_COMPILE
	for flag in (vim.env.NIX_CFLAGS_COMPILE or ""):gmatch("%S+") do
		add(flag)
	end

	-- pkg-config
	if vim.fn.executable("pkg-config") == 1 then
		for _, pkg in ipairs({ "raylib", "wayland-client", "wlroots", "gl", "glfw3", "sdl2", "libxkbcommon", "libinput" }) do
			local handle = io.popen(("pkg-config --cflags %s 2>/dev/null"):format(pkg))
			if handle then
				for flag in handle:read("*a"):gmatch("%S+") do add(flag) end
				handle:close()
			end
		end
	end

	return flags
end

vim.api.nvim_create_user_command("GenerateCompileFlags", function()
	local flags = M.get_nix_c_flags()
	local file, err = io.open(vim.fn.getcwd() .. "/compile_flags.txt", "w")
	if not file then
		vim.notify("Failed: " .. tostring(err), vim.log.levels.ERROR)
		return
	end
	for _, flag in ipairs(flags) do file:write(flag .. "\n") end
	file:close()
	vim.notify("Generated compile_flags.txt")
	pcall(vim.cmd, "LspRestart")
end, { desc = "Generate compile_flags.txt from environment & pkg-config" })

return M
