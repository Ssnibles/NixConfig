-- User configuration options
local CONFIG = {
	yank_highlight_timeout = 200,
	large_file_size_mb = 5,

	-- Filetypes to skip when trimming trailing whitespace on save
	trim_whitespace_skip_ft = {
		markdown = true,
		text = true,
		gitcommit = true,
		diff = true,
	},

	-- Filetypes closed by pressing 'q' or '<Esc>'
	close_with_q_ft = {
		"help",
		"man",
		"qf",
		"lspinfo",
		"checkhealth",
		"notify",
		"oil",
		"grug-far",
		"NeogitStatus",
		"cargo",
	},

	-- Filetypes with indent folding disabled by default
	fold_indent_ft = {
		"markdown",
		"markdown.mdx",
		"text",
		"gitcommit",
		"typst",
		"txt",
		"yaml",
		"json",
		"toml",
	},
}

local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Trims trailing whitespace and empty lines on save without re-parsing untouched lines
local function trim_trailing_whitespace()
	if vim.bo.buftype ~= "" or CONFIG.trim_whitespace_skip_ft[vim.bo.filetype] then
		return
	end

	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local modified = false

	-- Trim trailing whitespace per line
	for i, line in ipairs(lines) do
		local new_line = line:gsub("%s+$", "")
		if new_line ~= line then
			lines[i] = new_line
			modified = true
		end
	end

	-- Trim trailing blank lines at end of file
	local last = #lines
	while last > 1 and lines[last]:match("^%s*$") do
		last = last - 1
	end

	if last < #lines then
		for i = #lines, last + 1, -1 do
			table.remove(lines, i)
		end
		modified = true
	end

	-- Only touch the buffer if changes actually occurred to prevent syntax flashing
	if modified then
		vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
	end
end

-- Trims trailing whitespace before writing to disk
autocmd("BufWritePre", {
	group = augroup,
	callback = trim_trailing_whitespace,
})

-- Automatically enables LSP inlay hints once attached
autocmd("LspAttach", {
	group = augroup,
	callback = function(args)
		if vim.b[args.buf]._inlay_hints_auto_enabled then
			return
		end
		pcall(vim.lsp.inlay_hint.enable, true, { bufnr = args.buf })
		vim.b[args.buf]._inlay_hints_auto_enabled = true
	end,
})

-- Highlights yanked text briefly
autocmd("TextYankPost", {
	group = augroup,
	callback = function()
		vim.hl.on_yank({ timeout = CONFIG.yank_highlight_timeout })
	end,
})

-- Checks if files were changed outside Neovim when window gains focus
autocmd("FocusGained", {
	group = augroup,
	command = "checktime",
})

-- Restores cursor to last known position when opening a buffer
autocmd("BufReadPost", {
	group = augroup,
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(0) then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Binds 'q' and '<Esc>' to close utility windows
autocmd("FileType", {
	group = augroup,
	pattern = CONFIG.close_with_q_ft,
	callback = function(ev)
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
		vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
	end,
})

-- Equalizes window splits when Neovim window is resized
autocmd("VimResized", {
	group = augroup,
	command = "wincmd =",
})

-- Disables automatic comment insertion on new lines
autocmd("FileType", {
	group = augroup,
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Enables spell checking and line wrap for prose filetypes
autocmd("FileType", {
	group = augroup,
	pattern = { "markdown", "markdown.mdx", "text", "gitcommit" },
	callback = function(ev)
		vim.opt_local.spell = true
		vim.opt_local.wrap = true
		if vim.fn.has("nvim-0.12") == 1 then
			if vim.bo[ev.buf].filetype == "markdown" or vim.bo[ev.buf].filetype == "markdown.mdx" then
				pcall(vim.treesitter.stop, ev.buf)
			end
		end
	end,
})

-- Ensures signcolumn remains visible across window buffers
autocmd("BufWinEnter", {
	group = augroup,
	callback = function()
		local bt = vim.bo.buftype
		if bt == "terminal" or bt == "nofile" or bt == "acwrite" then
			return
		end
		if vim.wo.signcolumn == "no" then
			vim.wo.signcolumn = vim.o.signcolumn
		end
	end,
})

-- Switches to absolute line numbers in Insert and Visual modes, and relative numbers in all other modes
local line_number_group = vim.api.nvim_create_augroup("LineNumberModeToggle", { clear = true })
autocmd({ "ModeChanged", "BufEnter" }, {
	group = line_number_group,
	pattern = "*",
	callback = function()
		local bt = vim.bo.buftype
		if bt == "terminal" or bt == "nofile" or bt == "prompt" or bt == "quickfix" then
			return
		end

		-- Use new_mode from event context when available, falling back to current mode
		local mode = vim.v.event.new_mode or vim.api.nvim_get_mode().mode
		local first = mode:sub(1, 1)

		-- Match Insert ('i') or Visual modes ('v', 'V', or '\22' for blockwise)
		local is_insert_or_visual = (first == "i" or first == "v" or first == "V" or first == "\22")

		vim.wo.number = true
		vim.wo.relativenumber = not is_insert_or_visual
	end,
})

-- Toggles cursorline highlighting based on focused window
autocmd("WinEnter", {
	group = augroup,
	callback = function()
		if vim.bo.buftype ~= "terminal" then
			vim.wo.cursorline = true
		end
	end,
})
autocmd("WinLeave", {
	group = augroup,
	callback = function()
		if vim.bo.buftype ~= "terminal" then
			vim.wo.cursorline = false
		end
	end,
})

-- Sets indent foldmethod for structured text formats
autocmd("FileType", {
	group = augroup,
	pattern = CONFIG.fold_indent_ft,
	callback = function()
		vim.wo.foldmethod = "indent"
		vim.wo.foldenable = false
	end,
})

-- Sets keywordprg to Neovim help for Lua and Vimscript
autocmd("FileType", {
	group = augroup,
	pattern = { "lua", "vim" },
	callback = function()
		vim.bo.keywordprg = ":help"
	end,
})

-- Configures Typst preview and Zathura sync keymaps
autocmd("FileType", {
	group = augroup,
	pattern = "typst",
	callback = function()
		vim.keymap.set("n", "<leader>tp", function()
			vim.cmd("TypstPreviewToggle")
		end, { buffer = true, desc = "Toggle Typst preview" })

		vim.keymap.set("n", "<leader>zo", function()
			local buf_path = vim.fn.expand("%:p")
			local pdf_path = buf_path:gsub("%.typ$", ".pdf")
			if vim.fn.filereadable(pdf_path) == 1 then
				-- Spawns Zathura non-blocking detached process
				vim.system({
					"zathura",
					"--synctex-forward=" .. vim.fn.line(".") .. ":0:" .. buf_path,
					pdf_path,
				}, { detach = true })
			else
				vim.notify("PDF not found: " .. pdf_path, vim.log.levels.WARN)
			end
		end, { buffer = true, desc = "Open PDF in Zathura" })
	end,
})

-- Disables heavy syntax highlighting and folding for large files (>5MB)
autocmd({ "BufReadPre", "BufNewFile" }, {
	group = augroup,
	callback = function()
		local path = vim.fn.expand("<afile>:p")
		if vim.bo.buftype ~= "" or not vim.bo.modifiable then
			return
		end

		local ok, stat = pcall(vim.uv.fs_stat, path)
		if not ok or not stat then
			return
		end

		local size_mb = stat.size / (1024 * 1024)
		if size_mb > CONFIG.large_file_size_mb then
			vim.b.large_file = true
			vim.wo.foldmethod = "manual"
			vim.wo.foldenable = false
			vim.bo.syntax = ""
		end
	end,
})

-- Create an autocommand group for clean writing
local silent_write_grp = vim.api.nvim_create_augroup("SilentWrite", { clear = true })

local silent_write_grp = vim.api.nvim_create_augroup("SilentWrite", { clear = true })

vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = silent_write_grp,
    pattern = "*",
    callback = function(ev)
        local success, err = pcall(function()
            -- Execute write silently without triggering hit-enter prompts
            vim.cmd("silent! lockmarks write!")
        end)

        if not success then
            vim.api.nvim_echo({ { "Save Failed: " .. tostring(err), "ErrorMsg" } }, true, {})
        else
            -- Force a screen refresh to clear any command-line status messages
            vim.cmd("redraw!")
            vim.api.nvim_buf_set_var(ev.buf, "changed", 0)
        end
    end,
})
