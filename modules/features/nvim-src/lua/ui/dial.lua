-- Dial: smarter <C-a>/<C-x> for dates, hex, semver, booleans and friends.

local augend = require("dial.augend")

require("dial.config").augends:register_group({
	default = {
		augend.integer.alias.decimal,
		augend.integer.alias.hex,
		augend.integer.alias.binary,
		augend.integer.alias.octal,
		augend.date.alias["%Y-%m-%d"],
		augend.date.alias["%d.%m.%Y"],
		augend.date.alias["%H:%M:%S"],
		augend.constant.alias.bool,
		augend.semver.alias.semver,
	},
})

return require("dial.map")
