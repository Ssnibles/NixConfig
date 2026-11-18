-- UI base: icons, statusline and rendering plugins.

local icons = require("mini.icons")
icons.setup()
icons.mock_nvim_web_devicons()

require("ui.statusline")
require("ui.cmdline")
require("ui.msg")
require("ui.render")
require("ui.flash")
require("ui.splits")
require("ui.dial")
