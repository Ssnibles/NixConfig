-- Entry point. Nix installs every plugin and tool; this tree only configures
-- them. The tree is symlinked into ~/.config/nvim, so edits need no rebuild.
vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- ui2 draws ephemeral messages in a floating window and owns the cmdline, which
-- is what makes 'cmdheight=0' usable. Do not attach an ext_messages UI on top:
-- it externalises every message kind and silently drops the ones it does not
-- draw itself.
require("vim._core.ui2").enable({ msg = { targets = { default = "msg" } } })

require("options")
require("filetypes")
require("theme").setup()
require("ui")
