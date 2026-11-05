local dap = require("dap")

-- UI: nvim-dap-view keeps every section (scopes, threads, watches, breakpoints,
-- REPL, exceptions) in one window, unlike the dap-ui grid of floating panels.
-- It also renders variable values as inline virtual text.
local dap_view = require("dap-view")
dap_view.setup({
	auto_toggle = true,
	windows = { size = 0.3, position = "right" },
	winbar = { default_section = "scopes" },
	virtual_text = { enabled = true, position = "inline" },
})

-- Helpers

local util = require("util")

local function prompt_args(prompt)
	local line = vim.trim(vim.fn.input(prompt))
	return line == "" and {} or vim.split(line, "%s+")
end

local dap_utils = require("dap.utils")

-- Python

local debugpy = util.executable("debugpy-adapter")
if debugpy then
	require("dap-python").setup(debugpy)
	dap.configurations.python = {
		{
			type = "python",
			request = "launch",
			name = "Launch current file",
			program = "${file}",
			cwd = "${workspaceFolder}",
		},
		{
			type = "python",
			request = "launch",
			name = "Launch module",
			module = function()
				return vim.fn.input("Module: ")
			end,
			cwd = "${workspaceFolder}",
			args = function()
				return prompt_args("Args: ")
			end,
		},
		{
			type = "python",
			request = "launch",
			name = "Pytest current file",
			module = "pytest",
			args = { "${file}" },
			cwd = "${workspaceFolder}",
			justMyCode = false,
		},
	}
end

-- Go

local delve = util.executable("dlv")
if delve then
	dap.adapters.go = {
		type = "server",
		host = "127.0.0.1",
		port = "${port}",
		executable = { command = delve, args = { "dap", "-l", "127.0.0.1:${port}" } },
	}
	dap.configurations.go = {
		{ type = "go", name = "Debug package", request = "launch", program = "${workspaceFolder}" },
		{ type = "go", name = "Debug file", request = "launch", program = "${file}" },
		{
			type = "go",
			name = "Debug test",
			request = "launch",
			mode = "test",
			program = "${file}",
		},
	}
end

-- Java / Kotlin
-- Java debugging needs the `java-debug` adapter bundles driven through
-- nvim-jdtls; plain jdtls is not enough. It is intentionally left unwired
-- here so `:DapContinue` does not offer configurations that cannot start.

-- C / C++ / Rust (LLDB)

local lldb_adapter = util.lldb_dap_adapter()
if lldb_adapter then
	dap.adapters.lldb = lldb_adapter
	local function make_lldb_config(default_path_fn)
		return {
			{
				type = "lldb",
				request = "launch",
				name = "Launch executable",
				program = function()
					local cwd = vim.fn.getcwd()
					return vim.fn.input("Path to executable: ", default_path_fn(cwd), "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
				args = function()
					return prompt_args("Args: ")
				end,
			},
			{
				type = "lldb",
				request = "attach",
				name = "Attach to process",
				pid = dap_utils.pick_process,
				cwd = "${workspaceFolder}",
			},
		}
	end

	dap.configurations.c = make_lldb_config(function(cwd)
		return cwd .. "/"
	end)
	dap.configurations.cpp = vim.deepcopy(dap.configurations.c)
	dap.configurations.rust = make_lldb_config(function(cwd)
		return cwd .. "/target/debug/" .. vim.fn.fnamemodify(cwd, ":t")
	end)
end

-- JavaScript / TypeScript

local js_debug = util.first_executable({ "js-debug", "js-debug-adapter" })
if js_debug then
	dap.adapters["pwa-node"] = {
		type = "server",
		host = "127.0.0.1",
		port = "${port}",
		executable = { command = js_debug, args = { "${port}" } },
	}
	for _, lang in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
		dap.configurations[lang] = {
			{
				type = "pwa-node",
				request = "launch",
				name = "Launch current file",
				program = "${file}",
				cwd = "${workspaceFolder}",
				sourceMaps = true,
				console = "integratedTerminal",
			},
			{
				type = "pwa-node",
				request = "attach",
				name = "Attach to process",
				processId = dap_utils.pick_process,
				cwd = "${workspaceFolder}",
			},
		}
	end
end

-- Keymaps

local map = vim.keymap.set
map("n", "<leader>mb", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
map("n", "<leader>mB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional breakpoint" })
map("n", "<leader>mc", dap.continue, { desc = "Continue/start" })
map("n", "<leader>mi", dap.step_into, { desc = "Step into" })
map("n", "<leader>mo", dap.step_over, { desc = "Step over" })
map("n", "<leader>mO", dap.step_out, { desc = "Step out" })
map("n", "<leader>mr", function()
	dap_view.jump_to_view("repl")
end, { desc = "REPL" })
map("n", "<leader>mu", function()
	dap_view.toggle()
end, { desc = "DAP view toggle" })
map("n", "<leader>mw", function()
	dap_view.add_expr()
end, { desc = "Watch expression" })
map("n", "<leader>mh", function()
	dap_view.hover()
end, { desc = "Evaluate expression under cursor" })
map("n", "<leader>mt", dap.terminate, { desc = "Terminate" })
map("n", "<leader>mj", dap.down, { desc = "Go down in stack" })
map("n", "<leader>mk", dap.up, { desc = "Go up in stack" })
