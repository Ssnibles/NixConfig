-- Debugger: nvim-dap-view keeps every section in one window.

local dap_view = require("dap-view")

dap_view.setup({
	auto_toggle = true,
	windows = { size = 0.3, position = "right" },
	winbar = { default_section = "scopes" },
	virtual_text = { enabled = true, position = "inline" },
})

require("debugger.adapters")
