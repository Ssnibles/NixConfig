local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local sn = ls.snippet_node

local function wrap(trig, open, close, desc)
	return s({ trig = trig, desc = desc }, {
		t(open),
		i(1),
		t(close),
	})
end

ls.add_snippets("java", {
	wrap("pr", "System.out.print(", ")", "Print"),
	wrap("prl", "System.out.println(", ")", "Print Line"),

	s({ trig = "jd", desc = "JavaDoc Comment" }, {
		t({ "/**", " * " }),
		i(1),
		t({ "", " */" }),
	}),
})
