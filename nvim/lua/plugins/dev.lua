local dev_path = "/home/josh/projects/switcheroo"

if vim.fn.isdirectory(dev_path) == 1 then
	vim.opt.rtp:prepend(dev_path)
end

local ok, err = pcall(require, "switcheroo")
if not ok then
	vim.schedule(function()
		vim.notify(("switcheroo unavailable: %s"):format(err), vim.log.levels.WARN)
	end)
end
