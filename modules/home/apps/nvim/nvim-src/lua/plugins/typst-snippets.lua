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

ls.add_snippets("typst", {
	---------------------------------------------------------------------------
	-- DOCUMENT STRUCTURE, LAYOUT & HEADINGS
	---------------------------------------------------------------------------
	s({ trig = "page", desc = "New page configuration boilerplate" }, {
		t({ '#set page(paper: "a4", margin: (x: 2.5cm, y: 2.5cm))', "" }),
		t({ '#set text(font: "Liberation Sans", size: 12pt)', "" }),
		t({ "#set par(justify: true)", "", "" }),
		t("= "),
		i(1, "Title"),
		t({ "", "", "" }),
		i(2, "Content here..."),
	}),
	s({ trig = "h1", desc = "Heading level 1" }, { t("= "), i(1, "Heading") }),
	s({ trig = "h2", desc = "Heading level 2" }, { t("== "), i(1, "Heading") }),
	s({ trig = "h3", desc = "Heading level 3" }, { t("=== "), i(1, "Heading") }),
	s({ trig = "h4", desc = "Heading level 4" }, { t("==== "), i(1, "Heading") }),
	s({ trig = "col", desc = "Multi-column layout block" }, {
		t("#columns("),
		i(1, "2"),
		t(")["),
		t({ "", "" }),
		i(2),
		t({ "", "]" }),
	}),
	s({ trig = "align", desc = "Content alignment block (center, left, right)" }, {
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

	---------------------------------------------------------------------------
	-- INLINE TEXT FORMATTING
	---------------------------------------------------------------------------
	wrap("bf", "*", "*", "Bold text format"),
	wrap("it", "_", "_", "Italic text format"),
	wrap("st", "#strike[", "]", "Strikethrough text format"),
	wrap("hl", "#highlight[", "]", "Highlight text background"),
	wrap("sc", "#smallcaps[", "]", "Small caps text format"),
	wrap("sup", "#super[", "]", "Superscript text"),
	wrap("sub", "#sub[", "]", "Subscript text"),

	---------------------------------------------------------------------------
	-- GENERAL CONTENT ELEMENTS (IMAGES, TABLES, LINKS, TASKS)
	---------------------------------------------------------------------------
	s({ trig = "fig", desc = "Figure block with embedded image and caption" }, {
		t("#figure("),
		t({ "", '  image("' }),
		i(1, "path"),
		t('"),'),
		t({ "", "  caption: [" }),
		i(2, "Caption"),
		t("],"),
		t({ "", ")" }),
	}),
	s({ trig = "img", desc = "Image insertion element" }, { t('image("'), i(1, "path"), t('")') }),
	s({ trig = "tbl", desc = "Table block spanning full horizontal width with template entries" }, {
		t("#table("),
		t({ "", "  columns: (1fr, 1fr)," }), -- Full width divided equally between columns
		t({ "", '  fill: (x, y) => if y == 0 { rgb("efefef") } else { none },' }),
		t({ "", "  " }),
		i(1, "[Header 1], [Header 2],\n  [Row 1 Cell 1], [Row 1 Cell 2],\n  [Row 2 Cell 1], [Row 2 Cell 2]"),
		t({ "", ")" }),
	}),
	s(
		{ trig = "lnk", desc = "Hyperlink with custom display text" },
		{ t('#link("'), i(1, "url"), t('")[ '), i(2, "text"), t("]") }
	),
	s({ trig = "todo", desc = "Incomplete checkbox todo list item" }, { t("- [ ] "), i(1) }),
	s({ trig = "done", desc = "Completed checkbox todo list item" }, { t("- [x] "), i(1) }),

	---------------------------------------------------------------------------
	-- CALLOUTS & BOXES
	---------------------------------------------------------------------------
	s({ trig = "note", desc = "Note callout box with selectable border colours" }, {
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
	s({ trig = "def", desc = "Definition container box with blue border" }, {
		t({ "#box(stroke: 1pt + blue, inset: 8pt, radius: 4pt, width: 100%)[", "" }),
		t("*Definition:* "),
		i(1),
		t({ "", "]" }),
	}),
	s({ trig = "thm", desc = "Theorem container box with green border" }, {
		t({ "#box(stroke: 1pt + green, inset: 8pt, radius: 4pt, width: 100%)[", "" }),
		t("*Theorem:* "),
		i(1),
		t({ "", "]" }),
	}),
	s({ trig = "ex", desc = "Example container box with orange border" }, {
		t({ "#box(stroke: 1pt + orange, inset: 8pt, radius: 4pt, width: 100%)[", "" }),
		t("*Example:* "),
		i(1),
		t({ "", "]" }),
	}),

	---------------------------------------------------------------------------
	-- MATH ENVIRONMENTS & LAYOUT
	---------------------------------------------------------------------------
	s({ trig = "$", desc = "Inline math block" }, { t("$"), i(1), t("$") }),
	s({ trig = "$$", desc = "Display math block" }, { t("$ "), i(1), t(" $") }),
	s({ trig = "eq", desc = "Multi-line block equation syntax" }, {
		t({ "$ " }),
		i(1),
		t({ " \\", "  " }),
		i(2),
		t({ " \\", "  " }),
		i(3),
		t({ " $" }),
	}),
	s({ trig = "eqalign", desc = "Aligned block equation structure using ampersand relations" }, {
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

	---------------------------------------------------------------------------
	-- MATH FUNCTIONS & OPERATORS
	---------------------------------------------------------------------------
	s({ trig = "frac", desc = "Mathematical fraction symbol" }, { t("("), i(1, "num"), t(")/("), i(2, "den"), t(")") }),
	s(
		{ trig = "sum", desc = "Mathematical summation operator with limits" },
		{ t("sum_("), i(1, "i=0"), t(")^("), i(2, "n"), t(") "), i(3) }
	),
	s(
		{ trig = "prod", desc = "Mathematical product operator with limits" },
		{ t("prod_("), i(1, "i=0"), t(")^("), i(2, "n"), t(") "), i(3) }
	),
	s(
		{ trig = "int", desc = "Definite mathematical integral operator with bounds" },
		{ t("integral_("), i(1, "a"), t(")^("), i(2, "b"), t(") "), i(3) }
	),
	s(
		{ trig = "lim", desc = "Mathematical limit expression target" },
		{ t("lim_("), i(1, "x"), t(" -> "), i(2, "inf"), t(") "), i(3) }
	),
	s({ trig = "sqrt", desc = "Mathematical square root radical function" }, { t("sqrt("), i(1), t(")") }),
	s(
		{ trig = "root", desc = "Mathematical nth-order root function" },
		{ t("root("), i(1, "n"), t(", "), i(2, "x"), t(")") }
	),
	s({ trig = "abs", desc = "Absolute value bracket wrapper" }, { t("|"), i(1), t("|") }),
	s({ trig = "norm", desc = "Mathematical norm bracket wrapper" }, { t("||"), i(1), t("||") }),
	s(
		{ trig = "pdiff", desc = "Partial derivative fractional notation template" },
		{ t("(diff "), i(1, "f"), t(")/(diff "), i(2, "x"), t(")") }
	),
	s(
		{ trig = "diff", desc = "Total derivative fractional notation template" },
		{ t("(d "), i(1, "f"), t(")/(d "), i(2, "x"), t(")") }
	),
	s(
		{ trig = "binom", desc = "Binomial coefficient matrix notation" },
		{ t("binom("), i(1, "n"), t(", "), i(2, "k"), t(")") }
	),
	s({ trig = "ceil", desc = "Mathematical ceiling rounding bracket function" }, { t("ceil("), i(1), t(")") }),
	s({ trig = "floor", desc = "Mathematical floor rounding bracket function" }, { t("floor("), i(1), t(")") }),
	s({ trig = "cases", desc = "Piecewise math function cases container" }, { t("cases("), i(1), t(")") }),

	---------------------------------------------------------------------------
	-- MATRICES & LINEAR ALGEBRA
	---------------------------------------------------------------------------
	s({ trig = "vec", desc = "Vector column array template" }, { t("vec("), i(1), t(")") }),
	s({ trig = "mat", desc = "Generic structural matrix template" }, { t("mat("), i(1), t(")") }),
	s({ trig = "mat2", desc = "Two-by-two square matrix matrix notation template" }, {
		t("mat("),
		i(1, "a"),
		t(", "),
		i(2, "b"),
		t("; "),
		i(3, "c"),
		t(", "),
		i(4, "d"),
		t(")"),
	}),
	s({ trig = "mat3", desc = "Three-by-three square matrix notation template" }, {
		t("mat("),
		i(1, "a"),
		t(", "),
		i(2, "b"),
		t(", "),
		i(3, "c"),
		t("; "),
		i(4, "d"),
		t(", "),
		i(5, "e"),
		t(", "),
		i(6, "f"),
		t("; "),
		i(7, "g"),
		t(", "),
		i(8, "h"),
		t(", "),
		i(9, "i"),
		t(")"),
	}),
	s({ trig = "det", desc = "Matrix determinant operator prefix" }, { t("det "), i(1) }),
	s({ trig = "trace", desc = "Matrix trace operator prefix" }, { t("tr "), i(1) }),
	s({ trig = "transpose", desc = "Matrix transpose mathematical superscript" }, { i(1), t("^T") }),
	s({ trig = "inv", desc = "Matrix inverse mathematical power superscript" }, { i(1), t("^(-1)") }),

	---------------------------------------------------------------------------
	-- MATH ACCENTS & MODIFIERS
	---------------------------------------------------------------------------
	s({ trig = "conj", desc = "Complex conjugate modifier function" }, { t("conj("), i(1), t(")") }),
	s({ trig = "hat", desc = "Hat accent mathematical symbol modifier" }, { t("hat("), i(1), t(")") }),
	s({ trig = "bar", desc = "Overline bar accent mathematical symbol modifier" }, { t("overline("), i(1), t(")") }),
	s({ trig = "tilde", desc = "Tilde accent mathematical symbol modifier" }, { t("tilde("), i(1), t(")") }),
	s({ trig = "dot", desc = "Single dot accent mathematical symbol modifier" }, { t("dot("), i(1), t(")") }),
	s({ trig = "ddot", desc = "Double dot accent mathematical symbol modifier" }, { t("dot.double("), i(1), t(")") }),
	s({ trig = "lr", desc = "Dynamic sizing left-right parentheses wrapper" }, { t("lr("), i(1), t(")") }),
	s({ trig = "lrb", desc = "Dynamic sizing left-right square brackets wrapper" }, { t("lr(["), i(1), t("])") }),
	s({ trig = "lrc", desc = "Dynamic sizing left-right curly braces wrapper" }, { t("lr({"), i(1), t("})") }),

	---------------------------------------------------------------------------
	-- MATH SYMBOLS & LOGIC
	---------------------------------------------------------------------------
	s({ trig = "inff", desc = "Infinity mathematical symbol" }, { t("infinity") }),
	s({ trig = "nab", desc = "Nabla gradient mathematical operator" }, { t("nabla") }),
	s({ trig = "arr", desc = "Standard math relation arrow direction" }, { t("arrow") }),
	s({ trig = "rarr", desc = "Rightward pointing relation arrow" }, { t("arrow.r") }),
	s({ trig = "larr", desc = "Leftward pointing relation arrow" }, { t("arrow.l") }),
	s({ trig = "uarr", desc = "Upward pointing relation arrow" }, { t("arrow.t") }),
	s({ trig = "darr", desc = "Downward pointing relation arrow" }, { t("arrow.b") }),
	s({ trig = "iff", desc = "If and only if logical equivalence arrow" }, { t("<==>") }),
	s({ trig = "==>", desc = "Logical implication rightward relation arrow" }, { t("==>") }),
	s({ trig = "therefore", desc = "Therefore logical conclusion conclusion symbol" }, { t("therefore") }),
	s({ trig = "because", desc = "Because logical explanation symbol" }, { t("because") }),
	s({ trig = "forall", desc = "For all universal quantifier symbol" }, { t("forall") }),
	s({ trig = "exists", desc = "Exists existential quantifier symbol" }, { t("exists") }),
	s({ trig = "elem", desc = "Element of set membership symbol" }, { t("in") }),
	s({ trig = "notin", desc = "Not an element of set membership negation symbol" }, { t("in.not") }),
	s({ trig = "subs", desc = "Subset inclusion operation relation symbol" }, { t("subset") }),
	s({ trig = "cup", desc = "Union set operation symbol" }, { t("union") }),
	s({ trig = "cap", desc = "Intersection set operation symbol" }, { t("intersection") }),
	s({ trig = "empty", desc = "Empty set null space placeholder symbol" }, { t("nothing") }),

	---------------------------------------------------------------------------
	-- NUMBER SETS
	---------------------------------------------------------------------------
	s({ trig = "add", desc = "Set of real numbers blackboard bold identifier" }, { t("RR") }),
	s({ trig = "NN", desc = "Set of natural numbers blackboard bold identifier" }, { t("NN") }),
	s({ trig = "ZZ", desc = "Set of integers blackboard bold identifier" }, { t("ZZ") }),
	s({ trig = "QQ", desc = "Set of rational numbers blackboard bold identifier" }, { t("QQ") }),
	s({ trig = "CC", desc = "Set of complex numbers blackboard bold identifier" }, { t("CC") }),

	---------------------------------------------------------------------------
	-- GREEK LETTERS
	---------------------------------------------------------------------------
	s({ trig = "aa", desc = "Greek lowercase letter alpha" }, { t("alpha") }),
	s({ trig = "bb", desc = "Greek lowercase letter beta" }, { t("beta") }),
	s({ trig = "gg", desc = "Greek lowercase letter gamma" }, { t("gamma") }),
	s({ trig = "dd", desc = "Greek lowercase letter delta" }, { t("delta") }),
	s({ trig = "ee", desc = "Greek lowercase letter epsilon" }, { t("epsilon") }),
	s({ trig = "th", desc = "Greek lowercase letter theta" }, { t("theta") }),
	s({ trig = "ll", desc = "Greek lowercase letter lambda" }, { t("lambda") }),
	s({ trig = "mm", desc = "Greek lowercase letter mu" }, { t("mu") }),
	s({ trig = "pp", desc = "Greek lowercase letter pi" }, { t("pi") }),
	s({ trig = "ss", desc = "Greek lowercase letter sigma" }, { t("sigma") }),
	s({ trig = "oo", desc = "Greek lowercase letter omega" }, { t("omega") }),
	s({ trig = "ph", desc = "Greek lowercase letter phi" }, { t("phi") }),
	s({ trig = "ps", desc = "Greek lowercase letter psi" }, { t("psi") }),
	s({ trig = "rh", desc = "Greek lowercase letter rho" }, { t("rho") }),
	s({ trig = "ta", desc = "Greek lowercase letter tau" }, { t("tau") }),

	---------------------------------------------------------------------------
	-- CODE BLOCKS
	---------------------------------------------------------------------------
	s({ trig = "ic", desc = "Inline monospaced code snippet" }, { t("`"), i(1, "code"), t("`") }),
	s({ trig = "cb", desc = "Code block container with dynamic language identifier" }, {
		t("```"),
		i(1, "lang"),
		t({ "", "" }),
		i(2),
		t({ "", "```" }),
	}),
	s({ trig = "```", desc = "Raw typst interpretation text block container" }, {
		t("```"),
		i(1, "typ"),
		t({ "", "" }),
		i(2),
		t({ "", "```" }),
	}),
	s({ trig = "raw", desc = "Raw unhighlighted code text block container" }, {
		t({ "```", "" }),
		i(1),
		t({ "", "```" }),
	}),
	s(
		{ trig = "cbpy", desc = "Code block block specified for Python code syntax" },
		{ t({ "```py", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbrs", desc = "Code block block specified for Rust code syntax" },
		{ t({ "```rust", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbjs", desc = "Code block block specified for JavaScript code syntax" },
		{ t({ "```js", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbts", desc = "Code block block specified for TypeScript code syntax" },
		{ t({ "```ts", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbjava", desc = "Code block block specified for Java code syntax" },
		{ t({ "```java", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbc", desc = "Code block block specified for C programming language syntax" },
		{ t({ "```c", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbcpp", desc = "Code block block specified for C++ programming language syntax" },
		{ t({ "```cpp", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbsh", desc = "Code block block specified for Shell script programming syntax" },
		{ t({ "```sh", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbsql", desc = "Code block block specified for SQL database query syntax" },
		{ t({ "```sql", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbhtml", desc = "Code block block specified for HTML markup language syntax" },
		{ t({ "```html", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbcss", desc = "Code block block specified for CSS presentational language syntax" },
		{ t({ "```css", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbnix", desc = "Code block block specified for Nix package configuration syntax" },
		{ t({ "```nix", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cblua", desc = "Code block block specified for Lua configuration script syntax" },
		{ t({ "```lua", "" }), i(1), t({ "", "```" }) }
	),
	s(
		{ trig = "cbhs", desc = "Code block block specified for Haskell functional language syntax" },
		{ t({ "```hs", "" }), i(1), t({ "", "```" }) }
	),
})
