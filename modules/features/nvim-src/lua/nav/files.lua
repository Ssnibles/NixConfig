-- Oil file browser, plus pasting a clipboard image into the current directory.

local external = require("external")
local oil = require("oil")

local M = {}

require("oil").setup({
	columns = { "icon" },
	view_options = { show_hidden = true },
	float = { padding = 2, max_width = 0.8, max_height = 0.8 },
	keymaps = {
		["<C-h>"] = false,
		["<M-h>"] = "actions.select_split",
		["<leader>p"] = {
			callback = function()
				M.paste_image()
			end,
			desc = "Paste image from clipboard",
		},
	},
})

--- Save a PNG from the Wayland clipboard into the oil directory.
function M.paste_image()
	if vim.bo.filetype ~= "oil" then
		return
	end
	local wl_paste = external.wl_paste()
	if not wl_paste then
		vim.notify("wl-paste is not installed.", vim.log.levels.WARN)
		return
	end
	if not vim.system({ wl_paste, "--list-types" }):wait().stdout:match("image/png") then
		vim.notify("No PNG image in clipboard.", vim.log.levels.WARN)
		return
	end
	local dir = oil.get_current_dir()
	if not dir then
		return
	end

	vim.ui.input({
		prompt = "Save clipboard image as: ",
		default = "image_" .. os.date("%Y%m%d_%H%M%S") .. ".png",
	}, function(input)
		if not input or input == "" then
			return
		end
		if not input:match("%.png$") then
			input = input .. ".png"
		end

		local result = vim.system({ wl_paste, "-t", "image/png" }):wait()
		local file = result.code == 0 and io.open(dir .. input, "wb")
		if not file then
			vim.notify("Failed: " .. result.stderr, vim.log.levels.ERROR)
			return
		end
		file:write(result.stdout)
		file:close()
		vim.notify("Saved image to " .. input)
		oil.open(dir)
	end)
end

function M.toggle()
	oil.toggle_float()
end

vim.api.nvim_create_user_command("OilPasteImage", M.paste_image, {})

return M
