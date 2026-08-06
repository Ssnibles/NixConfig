local function paste_image_to_oil()
	-- Ensure we are inside an oil buffer
	if vim.bo.filetype ~= "oil" then
		vim.notify("This helper only works inside oil.nvim buffers.", vim.log.levels.WARN)
		return
	end

	-- Check if clipboard contains PNG data
	local targets = vim.fn.system("wl-paste --list-types")
	if not string.match(targets, "image/png") then
		vim.notify("No PNG image found in clipboard.", vim.log.levels.WARN)
		return
	end

	-- Get current directory from oil.nvim
	local oil = require("oil")
	local current_dir = oil.get_current_dir()
	if not current_dir then
		vim.notify("Could not determine current directory.", vim.log.levels.ERROR)
		return
	end

	-- Prompt for target file name
	local default_name = "image_" .. os.date("%Y%m%d_%H%M%S") .. ".png"
	vim.ui.input({
		prompt = "Save clipboard image as: ",
		default = default_name,
	}, function(input)
		if not input or input == "" then
			return
		end

		-- Ensure .png extension
		if not string.match(input, "%.png$") then
			input = input .. ".png"
		end

		local file_path = current_dir .. input

		-- Save image binary data using wl-paste
		local cmd = string.format("wl-paste -t image/png > %s", vim.fn.shellescape(file_path))
		local result = vim.fn.system(cmd)

		if vim.v.shell_error == 0 then
			vim.notify("Saved image to " .. input, vim.log.levels.INFO)
			-- Refresh oil buffer to display the new file immediately
			oil.open(current_dir)
		else
			vim.notify("Failed to save image: " .. result, vim.log.levels.ERROR)
		end
	end)
end

-- Create a user command for easy mapping
vim.api.nvim_create_user_command("OilPasteImage", paste_image_to_oil, {})

require("oil").setup({
	columns = { "icon" },
	view_options = { show_hidden = true },
	float = { padding = 2, max_width = 0.8, max_height = 0.8, border = "rounded" },
	keymaps = {
		["<C-h>"] = false,
		["<M-h>"] = "actions.select_split",
		["<leader>p"] = {
			callback = function()
				vim.cmd("OilPasteImage")
			end,
			desc = "Paste image from clipboard into current directory",
		},
	},
})

vim.keymap.set("n", "<leader>e", function()
	require("oil").toggle_float()
end, { desc = "Explorer (Oil)" })

require("gitsigns").setup({
	signcolumn = true,
	numhl = true,
	linehl = false,
	word_diff = false,
	current_line_blame = true,
	current_line_blame_opts = { virt_text = true, virt_text_pos = "eol", delay = 800, ignore_whitespace = false },
	current_line_blame_formatter = function(name, blame_info)
		if blame_info.author == name then
			blame_info.author = "You"
		end
		local now = os.time()
		local diff = now - blame_info.author_time
		local days = math.floor(diff / 86400)
		local time_str
		if days < 1 then
			time_str = "today"
		elseif days == 1 then
			time_str = "1 day ago"
		elseif days < 8 then
			time_str = days .. " days ago"
		else
			time_str = os.date("%d-%m-%Y", blame_info.author_time)
		end
		return {
			{
				string.format("  %s, %s — %s", blame_info.author, time_str, blame_info.summary),
				"GitSignsCurrentLineBlame",
			},
		}
	end,
	preview_config = { border = "rounded" },
	on_attach = function(bufnr)
		local gs = require("gitsigns")
		local map = function(mode, l, r, desc)
			vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
		end
		map("n", "]g", gs.next_hunk, "Next hunk")
		map("n", "[g", gs.prev_hunk, "Prev hunk")
		map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
		map("n", "<leader>gs", gs.stage_hunk, "Stage hunk")
		map("n", "<leader>gu", gs.reset_hunk, "Unstage/reset hunk")
		map("n", "<leader>gb", gs.blame_line, "Blame line")
		map("n", "<leader>gD", gs.diffthis, "Diff this")
	end,
})
