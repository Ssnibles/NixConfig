-- Debug adapters. Each one is wired only when its binary is present.
local dap = require("dap")
local dap_utils = require("dap.utils")
local external = require("external")

local function prompt_args(prompt)
	local line = vim.trim(vim.fn.input(prompt))
	return line == "" and {} or vim.split(line, "%s+")
end

-- Python
local debugpy = external.debugpy()
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
local delve = external.delve()
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
		{ type = "go", name = "Debug test", request = "launch", mode = "test", program = "${file}" },
	}
end

-- C, C++ and Rust (LLDB)
local lldb_adapter = external.lldb_dap_adapter()
if lldb_adapter then
	dap.adapters.lldb = lldb_adapter
	local function lldb_configurations(default_program)
		return {
			{
				type = "lldb",
				request = "launch",
				name = "Launch executable",
				program = function()
					return vim.fn.input("Path to executable: ", default_program(vim.fn.getcwd()), "file")
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
	dap.configurations.c = lldb_configurations(function(cwd)
		return cwd .. "/"
	end)
	dap.configurations.cpp = vim.deepcopy(dap.configurations.c)
	dap.configurations.rust = lldb_configurations(function(cwd)
		return cwd .. "/target/debug/" .. vim.fn.fnamemodify(cwd, ":t")
	end)
end

-- JavaScript and TypeScript
local js_debug = external.js_debug()
if js_debug then
	dap.adapters["pwa-node"] = {
		type = "server",
		host = "127.0.0.1",
		port = "${port}",
		executable = { command = js_debug, args = { "${port}" } },
	}
	for _, language in ipairs({ "javascript", "typescript", "javascriptreact", "typescriptreact" }) do
		dap.configurations[language] = {
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
