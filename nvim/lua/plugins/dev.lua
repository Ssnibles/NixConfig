local dev_path = "/home/josh/projects/switcheroo/"

if vim.fn.isdirectory(dev_path) == 1 then
	vim.opt.rtp:prepend(dev_path)
end

require("switcheroo")
