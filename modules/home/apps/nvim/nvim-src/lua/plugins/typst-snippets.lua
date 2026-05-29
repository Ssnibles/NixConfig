local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local fmt = require("luasnip.extras.fmt").fmt

local function rep(n)
	return ls.function_node(function(args)
		return args[1]
	end, { n })
end

local function wrap(trig, open, close, desc)
	return s({ trig = trig, desc = desc }, {
		t(open),
		i(1),
		t(close),
	})
end

ls.add_snippets("typst", {
	s({ trig = "h1", desc = "Heading 1" }, { t("= "), i(1, "Heading") }),
	s({ trig = "h2", desc = "Heading 2" }, { t("== "), i(1, "Heading") }),
	s({ trig = "h3", desc = "Heading 3" }, { t("=== "), i(1, "Heading") }),
	s({ trig = "h4", desc = "Heading 4" }, { t("==== "), i(1, "Heading") }),

	wrap("bf", "*", "*", "Bold"),
	wrap("it", "_", "_", "Italic"),
	wrap("st", "#strike[", "]", "Strikethrough"),
	wrap("hl", "#highlight[", "]", "Highlight"),
	wrap("sc", "#smallcaps[", "]", "Smallcaps"),
	wrap("sup", "#super[", "]", "Superscript"),
	wrap("sub", "#sub[", "]", "Subscript"),

	s({ trig = "ic", desc = "Inline code" }, { t("`"), i(1, "code"), t("`") }),
	s({ trig = "cb", desc = "Code block" }, {
		t("```"),
		i(1, "lang"),
		t({ "", "" }),
		i(2),
		t({ "", "```" }),
	}),

	s({ trig = "$", desc = "Inline math" }, { t("$"), i(1), t("$") }),
	s({ trig = "$$", desc = "Display math" }, {
		t("$ "),
		i(1),
		t(" $"),
	}),
	s({ trig = "frac", desc = "Fraction" }, {
		t("("),
		i(1, "num"),
		t(")/("),
		i(2, "den"),
		t(")"),
	}),
	s({ trig = "sum", desc = "Summation" }, {
		t("sum_("),
		i(1, "i=0"),
		t(")^("),
		i(2, "n"),
		t(") "),
		i(3),
	}),
	s({ trig = "prod", desc = "Product" }, {
		t("prod_("),
		i(1, "i=0"),
		t(")^("),
		i(2, "n"),
		t(") "),
		i(3),
	}),
	s({ trig = "int", desc = "Integral" }, {
		t("integral_("),
		i(1, "a"),
		t(")^("),
		i(2, "b"),
		t(") "),
		i(3),
	}),
	s({ trig = "lim", desc = "Limit" }, {
		t("lim_("),
		i(1, "x"),
		t(" -> "),
		i(2, "inf"),
		t(") "),
		i(3),
	}),
	s({ trig = "vec", desc = "Vector" }, { t("vec("), i(1), t(")") }),
	s({ trig = "mat", desc = "Matrix" }, { t("mat("), i(1), t(")") }),
	s({ trig = "cases", desc = "Cases (piecewise)" }, {
		t("cases("),
		i(1),
		t(")"),
	}),

	s({ trig = "sqrt", desc = "Square root" }, { t("sqrt("), i(1), t(")") }),
	s({ trig = "root", desc = "Nth root" }, { t("root("), i(1, "n"), t(", "), i(2, "x"), t(")") }),
	s({ trig = "abs", desc = "Absolute value" }, { t("|"), i(1), t("|") }),
	s({ trig = "norm", desc = "Norm" }, { t("||"), i(1), t("||") }),
	s({ trig = "inff", desc = "Infinity" }, { t("infinity") }),
	s({ trig = "nab", desc = "Nabla" }, { t("nabla") }),
	s({ trig = "pdiff", desc = "Partial derivative" }, {
		t("(diff "),
		i(1, "f"),
		t(")/(diff "),
		i(2, "x"),
		t(")"),
	}),
	s({ trig = "diff", desc = "Derivative" }, {
		t("(d "),
		i(1, "f"),
		t(")/(d "),
		i(2, "x"),
		t(")"),
	}),
	s({ trig = "binom", desc = "Binomial coefficient" }, { t("binom("), i(1, "n"), t(", "), i(2, "k"), t(")") }),
	s({ trig = "ceil", desc = "Ceiling" }, { t("ceil("), i(1), t(")") }),
	s({ trig = "floor", desc = "Floor" }, { t("floor("), i(1), t(")") }),
	s({ trig = "conj", desc = "Conjugate" }, { t("conj("), i(1), t(")") }),
	s({ trig = "hat", desc = "Hat accent" }, { t("hat("), i(1), t(")") }),
	s({ trig = "bar", desc = "Overline" }, { t("overline("), i(1), t(")") }),
	s({ trig = "tilde", desc = "Tilde accent" }, { t("tilde("), i(1), t(")") }),
	s({ trig = "dot", desc = "Dot accent" }, { t("dot("), i(1), t(")") }),
	s({ trig = "ddot", desc = "Double dot accent" }, { t("dot.double("), i(1), t(")") }),
	s({ trig = "arr", desc = "Arrow" }, { t("arrow") }),
	s({ trig = "rarr", desc = "Right arrow" }, { t("arrow.r") }),
	s({ trig = "larr", desc = "Left arrow" }, { t("arrow.l") }),
	s({ trig = "uarr", desc = "Up arrow" }, { t("arrow.t") }),
	s({ trig = "darr", desc = "Down arrow" }, { t("arrow.b") }),
	s({ trig = "iff", desc = "If and only if" }, { t("<==>") }),
	s({ trig = "==>", desc = "Implies" }, { t("==>") }),
	s({ trig = "therefore", desc = "Therefore" }, { t("therefore") }),
	s({ trig = "because", desc = "Because" }, { t("because") }),
	s({ trig = "forall", desc = "For all" }, { t("forall") }),
	s({ trig = "exists", desc = "Exists" }, { t("exists") }),
	s({ trig = "elem", desc = "Element of" }, { t("in") }),
	s({ trig = "notin", desc = "Not element of" }, { t("in.not") }),
	s({ trig = "subs", desc = "Subset" }, { t("subset") }),
	s({ trig = "cup", desc = "Union" }, { t("union") }),
	s({ trig = "cap", desc = "Intersection" }, { t("intersection") }),
	s({ trig = "empty", desc = "Empty set" }, { t("nothing") }),
	s({ trig = "RR", desc = "Reals" }, { t("RR") }),
	s({ trig = "NN", desc = "Naturals" }, { t("NN") }),
	s({ trig = "ZZ", desc = "Integers" }, { t("ZZ") }),
	s({ trig = "QQ", desc = "Rationals" }, { t("QQ") }),
	s({ trig = "CC", desc = "Complex" }, { t("CC") }),
	s({ trig = "lr", desc = "Left-right parens" }, { t("lr("), i(1), t(")") }),
	s({ trig = "lrb", desc = "Left-right brackets" }, { t("lr(["), i(1), t("])") }),
	s({ trig = "lrc", desc = "Left-right braces" }, { t("lr({"), i(1), t("})") }),

	s({ trig = "eq", desc = "Equation block" }, {
		t({ "$ " }),
		i(1),
		t({ " \\", "  " }),
		i(2),
		t({ " \\", "  " }),
		i(3),
		t({ " $" }),
	}),
	s({ trig = "eqalign", desc = "Aligned equations" }, {
		t({ "$ " }),
		i(1),
		t(" &="),
		i(2),
		t({ " \\", "  " }),
		i(3),
		t(" &="),
		i(4),
		t({ " $" }),
	}),
	s({ trig = "mat2", desc = "2x2 Matrix" }, {
		t("mat("),
		i(1, "a"), t(", "), i(2, "b"), t("; "),
		i(3, "c"), t(", "), i(4, "d"),
		t(")"),
	}),
	s({ trig = "mat3", desc = "3x3 Matrix" }, {
		t("mat("),
		i(1, "a"), t(", "), i(2, "b"), t(", "), i(3, "c"), t("; "),
		i(4, "d"), t(", "), i(5, "e"), t(", "), i(6, "f"), t("; "),
		i(7, "g"), t(", "), i(8, "h"), t(", "), i(9, "i"),
		t(")"),
	}),
	s({ trig = "det", desc = "Determinant" }, { t("det "), i(1) }),
	s({ trig = "trace", desc = "Trace" }, { t("tr "), i(1) }),
	s({ trig = "transpose", desc = "Transpose" }, { i(1), t("^T") }),
	s({ trig = "inv", desc = "Inverse" }, { i(1), t("^(-1)") }),

	s({ trig = "cbpy", desc = "Python code block" }, {
		t({ "```py", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbrs", desc = "Rust code block" }, {
		t({ "```rust", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbjs", desc = "JavaScript code block" }, {
		t({ "```js", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbts", desc = "TypeScript code block" }, {
		t({ "```ts", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbjava", desc = "Java code block" }, {
		t({ "```java", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbc", desc = "C code block" }, {
		t({ "```c", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbcpp", desc = "C++ code block" }, {
		t({ "```cpp", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbsh", desc = "Shell code block" }, {
		t({ "```sh", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbsql", desc = "SQL code block" }, {
		t({ "```sql", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbhtml", desc = "HTML code block" }, {
		t({ "```html", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbcss", desc = "CSS code block" }, {
		t({ "```css", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbnix", desc = "Nix code block" }, {
		t({ "```nix", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cblua", desc = "Lua code block" }, {
		t({ "```lua", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "cbhs", desc = "Haskell code block" }, {
		t({ "```hs", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s({ trig = "raw", desc = "Raw block (no highlight)" }, {
		t({ "```", "" }),
		i(1),
		t({ "", "```" }),
	}),

	s({ trig = "aa", desc = "Alpha" }, { t("alpha") }),
	s({ trig = "bb", desc = "Beta" }, { t("beta") }),
	s({ trig = "gg", desc = "Gamma" }, { t("gamma") }),
	s({ trig = "dd", desc = "Delta" }, { t("delta") }),
	s({ trig = "ee", desc = "Epsilon" }, { t("epsilon") }),
	s({ trig = "th", desc = "Theta" }, { t("theta") }),
	s({ trig = "ll", desc = "Lambda" }, { t("lambda") }),
	s({ trig = "mm", desc = "Mu" }, { t("mu") }),
	s({ trig = "pp", desc = "Pi" }, { t("pi") }),
	s({ trig = "ss", desc = "Sigma" }, { t("sigma") }),
	s({ trig = "oo", desc = "Omega" }, { t("omega") }),
	s({ trig = "ph", desc = "Phi" }, { t("phi") }),
	s({ trig = "ps", desc = "Psi" }, { t("psi") }),
	s({ trig = "rh", desc = "Rho" }, { t("rho") }),
	s({ trig = "ta", desc = "Tau" }, { t("tau") }),

	s({ trig = "note", desc = "Note box" }, {
		t("#box(stroke: 1pt + "),
		c(1, {
			sn(nil, { t("blue") }),
			sn(nil, { t("green") }),
			sn(nil, { t("red") }),
			sn(nil, { t("orange") }),
			sn(nil, { t("purple") }),
		}),
		t({ ", inset: 8pt, radius: 4pt, width: 100%)[", "" }),
		i(2, "Note"),
		t({ "", "]" }),
	}),

	s({ trig = "def", desc = "Definition" }, {
		t({ "#box(stroke: 1pt + blue, inset: 8pt, radius: 4pt, width: 100%)[", "" }),
		t("*Definition:* "),
		i(1),
		t({ "", "]" }),
	}),

	s({ trig = "thm", desc = "Theorem" }, {
		t({ "#box(stroke: 1pt + green, inset: 8pt, radius: 4pt, width: 100%)[", "" }),
		t("*Theorem:* "),
		i(1),
		t({ "", "]" }),
	}),

	s({ trig = "ex", desc = "Example" }, {
		t({ "#box(stroke: 1pt + orange, inset: 8pt, radius: 4pt, width: 100%)[", "" }),
		t("*Example:* "),
		i(1),
		t({ "", "]" }),
	}),

	s({ trig = "todo", desc = "Todo item" }, { t("- [ ] "), i(1) }),
	s({ trig = "done", desc = "Done item" }, { t("- [x] "), i(1) }),

	s({ trig = "fig", desc = "Figure" }, {
		t("#figure("),
		t({ "", "  image(\"" }),
		i(1, "path"),
		t("\"),"),
		t({ "", "  caption: [" }),
		i(2, "Caption"),
		t("],"),
		t({ "", ")" }),
	}),

	s({ trig = "img", desc = "Image" }, { t("image(\""), i(1, "path"), t("\")") }),

	s({ trig = "tbl", desc = "Table" }, {
		t("#table("),
		t({ "", "  columns: " }),
		i(1, "2"),
		t(","),
		t({ "", "  " }),
		i(2, "content"),
		t({ "", ")" }),
	}),

	s({ trig = "lnk", desc = "Link" }, { t("#link(\""), i(1, "url"), t("\")[ "), i(2, "text"), t("]") }),

	s({ trig = "col", desc = "Columns" }, {
		t("#columns("),
		i(1, "2"),
		t(")["),
		t({ "", "" }),
		i(2),
		t({ "", "]" }),
	}),

	s({ trig = "align", desc = "Aligned block" }, {
		t("#align("),
		c(1, {
			sn(nil, { t("center") }),
			sn(nil, { t("left") }),
			sn(nil, { t("right") }),
		}),
		t(")["),
		t({ "", "" }),
		i(2),
		t({ "", "]" }),
	}),

	s({ trig = "```", desc = "Raw block" }, {
		t("```"),
		i(1, "typ"),
		t({ "", "" }),
		i(2),
		t({ "", "```" }),
	}),
})
