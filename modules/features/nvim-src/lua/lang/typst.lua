-- Typst: external preview, Zathura synctex and the #noln / #ln surroundings.

local external = require("external")

require("typst-preview").setup({
	get_root = function(path)
		return os.getenv("TYPST_ROOT") or vim.fn.fnamemodify(path, ":h")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("UserTypst", { clear = true }),
	pattern = "typst",
	callback = function(ev)
		-- `san` wraps in `#noln[...]`, `sal` in `#ln[...]`.
		vim.b[ev.buf].minisurround_config = {
			custom_surroundings = {
				n = { output = { left = "#noln[", right = "]" } },
				l = { output = { left = "#ln[", right = "]" } },
			},
		}

		vim.keymap.set("n", "<leader>tp", "<cmd>TypstPreviewToggle<CR>", {
			buffer = ev.buf,
			desc = "Toggle Typst preview",
		})

		vim.keymap.set("n", "<leader>zo", function()
			local pdf = vim.fn.expand("%:p:r") .. ".pdf"
			if vim.fn.filereadable(pdf) ~= 1 then
				vim.notify("PDF not found: " .. pdf, vim.log.levels.WARN)
				return
			end
			local zathura = external.zathura()
			if not zathura then
				vim.notify("zathura is not installed.", vim.log.levels.WARN)
				return
			end
			vim.system({
				zathura,
				"--synctex-forward=" .. vim.fn.line(".") .. ":0:" .. vim.api.nvim_buf_get_name(ev.buf),
				pdf,
			}, { detach = true })
		end, { buffer = ev.buf, desc = "Open PDF in Zathura" })
	end,
})
