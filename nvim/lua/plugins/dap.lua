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

local debugpy = executable("debugpy-adapter")
if debugpy then
	require("dap-python").setup(debugpy)
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
			name = "Launch .NET",
			request = "launch",
			program = function()
				return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/", "file")
			end,
			cwd = "${workspaceFolder}",
			stopAtEntry = false,
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

	for _, lang in ipairs({ "javascript", "typescript" }) do
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
				processId = require("dap.utils").pick_process,
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
