-- Debugging: nvim-dap + dap-ui + virtual text
local dap = require("dap")
local dapui = require("dapui")

dapui.setup({
	icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
	controls = {
		enabled = true,
		element = "repl",
	},
	floating = {
		border = "rounded",
	},
})

require("nvim-dap-virtual-text").setup({
	enabled = true,
	enabled_commands = true,
	highlight_changed_variables = true,
	virt_text_pos = "eol",
	all_frames = false,
})

dap.listeners.before.attach.dapui_config = function()
	dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
	dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
	dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
	dapui.close()
end

local function executable(cmd)
	return vim.fn.executable(cmd) == 1 and vim.fn.exepath(cmd) or nil
end

local function first_executable(commands)
	for _, cmd in ipairs(commands) do
		local path = executable(cmd)
		if path then
			return path
		end
	end
	return nil
end

local function prompt_args(prompt)
	local line = vim.trim(vim.fn.input(prompt))
	if line == "" then
		return {}
	end
	return vim.split(line, "%s+")
end

local dap_utils = require("dap.utils")

local debugpy = executable("debugpy-adapter")
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

local netcoredbg = executable("netcoredbg")
if netcoredbg then
	dap.adapters.coreclr = {
		type = "executable",
		command = netcoredbg,
		args = { "--interpreter=vscode" },
	}
	dap.configurations.cs = {
		{
			type = "coreclr",
			name = "Launch .NET DLL",
			request = "launch",
			program = function()
				return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
			end,
			cwd = "${workspaceFolder}",
			stopAtEntry = false,
		},
		{
			type = "coreclr",
			name = "Attach to process",
			request = "attach",
			processId = dap_utils.pick_process,
		},
	}
end

local delve = executable("dlv")
if delve then
	dap.adapters.go = {
		type = "server",
		host = "127.0.0.1",
		port = "${port}",
		executable = {
			command = delve,
			args = { "dap", "-l", "127.0.0.1:${port}" },
		},
	}
	dap.configurations.go = {
		{
			type = "go",
			name = "Debug package",
			request = "launch",
			program = "${workspaceFolder}",
		},
		{
			type = "go",
			name = "Debug file",
			request = "launch",
			program = "${file}",
		},
	}
end

dap.adapters.java = function(callback, config)
	callback({
		type = "server",
		host = config.hostName or "127.0.0.1",
		port = config.port or 5005,
	})
end

dap.configurations.java = {
	{
		type = "java",
		request = "attach",
		name = "Attach to localhost:5005",
		hostName = "127.0.0.1",
		port = 5005,
	},
	{
		type = "java",
		request = "attach",
		name = "Attach to custom host/port",
		hostName = function()
			local host = vim.fn.input("Host: ", "127.0.0.1")
			return host ~= "" and host or "127.0.0.1"
		end,
		port = function()
			local port = tonumber(vim.fn.input("Port: ", "5005"))
			return port or 5005
		end,
	},
}

dap.configurations.kotlin = vim.deepcopy(dap.configurations.java)

local lldb = first_executable({ "codelldb", "lldb-dap", "lldb-vscode" })
if lldb then
	if lldb:match("codelldb$") then
		dap.adapters.lldb = {
			type = "server",
			port = "${port}",
			executable = {
				command = lldb,
				args = { "--port", "${port}" },
			},
		}
	else
		dap.adapters.lldb = {
			type = "executable",
			command = lldb,
			name = "lldb",
		}
	end

	local lldb_configs = {
		{
			type = "lldb",
			request = "launch",
			name = "Launch executable",
			program = function()
				local cwd = vim.fn.getcwd()
				local default = cwd .. "/target/debug/" .. vim.fn.fnamemodify(cwd, ":t")
				return vim.fn.input("Path to executable: ", default, "file")
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

	dap.configurations.rust = vim.deepcopy(lldb_configs)
	dap.configurations.c = vim.deepcopy(lldb_configs)
	dap.configurations.cpp = vim.deepcopy(lldb_configs)
end

local js_debug = executable("js-debug-adapter")
if js_debug then
	dap.adapters["pwa-node"] = {
		type = "server",
		host = "127.0.0.1",
		port = "${port}",
		executable = {
			command = js_debug,
			args = { "${port}" },
		},
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

local map = vim.keymap.set
map("n", "<leader>mb", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
map("n", "<leader>mB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "DAP conditional breakpoint" })
map("n", "<leader>mc", dap.continue, { desc = "DAP continue/start" })
map("n", "<leader>mi", dap.step_into, { desc = "DAP step into" })
map("n", "<leader>mo", dap.step_over, { desc = "DAP step over" })
map("n", "<leader>mO", dap.step_out, { desc = "DAP step out" })
map("n", "<leader>mr", dap.repl.toggle, { desc = "DAP REPL" })
map("n", "<leader>mu", dapui.toggle, { desc = "DAP UI toggle" })
map("n", "<leader>mt", dap.terminate, { desc = "DAP terminate" })
