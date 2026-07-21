local v = vim.version()
return (v.major > 0) or (v.major == 0 and v.minor >= 12)
