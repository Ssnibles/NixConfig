-- Small user commands.

vim.api.nvim_create_user_command("Mes", 'new | put =execute("messages")', {})
