-- SmartRename: one prompt offering the LSP rename, a literal project replace
-- or a regex project replace, depending on what the cursor is on.
local lsp = vim.lsp
require("inc_rename").setup({})
local function supports_lsp_rename(bufnr)
	return vim.iter(lsp.get_clients({ bufnr = bufnr })):any(function(client)
		return client:supports_method("textDocument/rename", bufnr)
	end)
end
local function prompt_lsp_rename()
	local name = vim.fn.expand("<cword>")
	if name == "" then
		lsp.buf.rename()
		return
	end
	vim.ui.input({ prompt = "Rename symbol to: ", default = name }, function(new)
		if new and new ~= "" and new ~= name then
			lsp.buf.rename(new)
		end
	end)
end
local function escape_rg(text)
	return (text:gsub("([%(%)%.%+%-%*%?%[%]%^%$%{%}%|\\])", "\\%1"))
end
local function open_grug_far(prefills)
	local instance = require("grug-far").open({ prefills = prefills })
	if instance and type(instance.when_ready) == "function" and type(instance.goto_input) == "function" then
		instance:when_ready(function()
			instance:goto_input("replacement")
		end)
	end
end
vim.api.nvim_create_user_command("SmartRename", function()
	local bufnr = vim.api.nvim_get_current_buf()
	local word = vim.fn.expand("<cword>")
	local choices = {}
	if supports_lsp_rename(bufnr) then
		choices[#choices + 1] = { label = "LSP symbol rename (recommended)", action = prompt_lsp_rename }
	end
	if word ~= "" then
		choices[#choices + 1] = {
			label = "Project replace word (literal)",
			action = function()
				open_grug_far({ search = word, flags = "--fixed-strings --word-regexp" })
			end,
		}
		choices[#choices + 1] = {
			label = "Project replace regex",
			action = function()
				open_grug_far({ search = ("\\b%s\\b"):format(escape_rg(word)) })
			end,
		}
	end
	if #choices == 0 then
		vim.notify("No rename target: place cursor on a word", vim.log.levels.WARN)
	elseif #choices == 1 then
		choices[1].action()
	else
		vim.ui.select(choices, {
			prompt = "Rename/replace mode:",
			format_item = function(item)
				return item.label
			end,
		}, function(choice)
			if choice then
				choice.action()
			end
		end)
	end
end, { desc = "Context-aware rename and replace" })
