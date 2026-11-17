local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local c = ls.choice_node
local sn = ls.snippet_node
local d = ls.dynamic_node
local rep = require("luasnip.extras").rep

-- Helper for simple text wrapping
local function wrap(trig, open, close, desc)
	return s({ trig = trig, desc = desc }, {
		t(open),
		i(1),
		t(close),
	})
end

-- Helper for static single-token / symbol snippets
local function sym(trig, text, desc)
	return s({ trig = trig, desc = desc }, { t(text) })
end

-- Helper for bordered tables with header row and tabstop cells
local function make_table(trig, ncols, nrows, hdr_fmt, cell_fmt, desc)
	local auto_cols = {}
	for _ = 1, ncols do
		table.insert(auto_cols, "auto")
	end
	local nodes = {
		t({
			"#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[",
			"  #table(",
			"    columns: (" .. table.concat(auto_cols, ", ") .. "),",
			"    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },",
			"    inset: (x: 10pt, y: 6pt),",
			"    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),",
			"    table.header([*",
		}),
	}
	local idx = 1
	for col = 1, ncols do
		if col > 1 then
			table.insert(nodes, t("*], [*"))
		end
		table.insert(nodes, i(idx, string.format(hdr_fmt, col)))
		idx = idx + 1
	end
	table.insert(nodes, t("*]),"))
	for row = 1, nrows do
		table.insert(nodes, t({ "", "    [" }))
		for col = 1, ncols do
			if col > 1 then
				table.insert(nodes, t("], ["))
			end
			table.insert(nodes, i(idx, string.format(cell_fmt, row, col)))
			idx = idx + 1
		end
		table.insert(nodes, t("],"))
	end
	table.insert(nodes, t({ "", "  )", "]" }))
	return s({ trig = trig, desc = desc }, nodes)
end

-- Helper for uniform callout blocks with icons, names, borders, and background fills
-- Callouts now expand to the theme helper (`#callout(icon, title, colour, body)`)
-- rather than the verbose `#block(...)` markup, matching how notes actually use them.
local function make_callout(trig, title, icon, colour_hex, desc)
	return s({ trig = trig, desc = desc }, {
		t('#callout("' .. icon .. '", "'),
		i(1, title .. ":"),
		t('", "' .. colour_hex .. '")['),
		i(2, "Content..."),
		t("]"),
	})
end

-- Helper for language code blocks
local function make_codeblock(trig, lang, desc)
	return s({ trig = trig, desc = desc }, {
		t({ "```" .. lang, "" }),
		i(1),
		t({ "", "```" }),
	})
end

-- Shared body for the `#show raw` rule snippet, registered under two
-- triggers (`code-show-rule` and its `raw-show-rule` alias).
local function raw_show_rule(trig, desc)
	return s({ trig = trig, desc = desc }, {
		t({
			"// Language metadata: nerd font devicon + file extension",
			"#let lang-meta = (",
			'  py:      (icon: "\\u{E606}", ext: ".py"),',
			'  python:  (icon: "\\u{E606}", ext: ".py"),',
			'  js:      (icon: "\\u{E74E}", ext: ".js"),',
			'  ts:      (icon: "\\u{E628}", ext: ".ts"),',
			'  rust:    (icon: "\\u{E7A8}", ext: ".rs"),',
			'  rs:      (icon: "\\u{E7A8}", ext: ".rs"),',
			'  c:       (icon: "\\u{E61E}", ext: ".c"),',
			'  cpp:     (icon: "\\u{E61D}", ext: ".cpp"),',
			'  java:    (icon: "\\u{E738}", ext: ".java"),',
			'  go:      (icon: "\\u{E626}", ext: ".go"),',
			'  sh:      (icon: "\\u{E795}", ext: ".sh"),',
			'  bash:    (icon: "\\u{E795}", ext: ".sh"),',
			'  html:    (icon: "\\u{E736}", ext: ".html"),',
			'  css:     (icon: "\\u{E749}", ext: ".css"),',
			'  nix:     (icon: "\\u{F313}", ext: ".nix"),',
			'  lua:     (icon: "\\u{E620}", ext: ".lua"),',
			'  sql:     (icon: "\\u{E706}", ext: ".sql"),',
			'  json:    (icon: "\\u{E60B}", ext: ".json"),',
			'  yaml:    (icon: "\\u{E60B}", ext: ".yaml"),',
			'  md:      (icon: "\\u{E73E}", ext: ".md"),',
			'  asm:     (icon: "\\u{E637}", ext: ".asm"),',
			'  hs:      (icon: "\\u{E777}", ext: ".hs"),',
			'  php:     (icon: "\\u{E73D}", ext: ".php"),',
			'  xml:     (icon: "\\u{E8EA}", ext: ".xml"),',
			'  verilog: (icon: "\\u{F2DB}", ext: ".v"),',
			'  v:       (icon: "\\u{F2DB}", ext: ".v"),',
			'  tcl:     (icon: "\\u{EAC4}", ext: ".tcl"),',
			'  gradle:  (icon: "\\u{E7F2}", ext: ".gradle"),',
			'  cs:      (icon: "\\u{E7B2}", ext: ".cs"),',
			'  csharp:  (icon: "\\u{E7B2}", ext: ".cs"),',
			'  http:    (icon: "\\u{F0AC}", ext: ".http"),',
			'  txt:     (icon: "\\u{F15C}", ext: ".txt"),',
			'  toml:    (icon: "\\u{E6B2}", ext: ".toml"),',
			'  dockerfile: (icon: "\\u{E7B0}", ext: ""),',
			'  kotlin:  (icon: "\\u{E81B}", ext: ".kt"),',
			'  swift:   (icon: "\\u{E755}", ext: ".swift"),',
			'  r:       (icon: "\\u{E895}", ext: ".r"),',
			")",
			"// Styled code blocks: actual background with language header bar",
			"#show raw.where(block: true): it => {",
			'  let lang = if it.lang != none { it.lang } else { "" }',
			'  let lines = it.text.split("\\n")',
			'  let filename = if lines.len() > 1 and not lines.first().contains(" ") { lines.first() } else { "" }',
			'  let meta = lang-meta.at(lang, default: (icon: "\\u{F121}", ext: "." + lang))',
			'  let display = if filename == "" { lang } else if filename.contains(".") { filename } else { filename + meta.ext }',
			'  let bodylines = it.lines.slice(if filename != "" { 1 } else { 0 })',
			"  block(",
			"    width: 100%,",
			"    radius: ui-radius,",
			"    stroke: 0.5pt + ui-border,",
			"    fill: ui-surface,",
			"    clip: true,",
			"    stack(",
			"      dir: ttb,",
			"      spacing: 0pt,",
			'      ..if lang != "" {',
			"        (",
			"          block(",
			"            width: 100%,",
			"            fill: ui-surface-raised,",
			"            inset: (x: 12pt, y: 6pt),",
			"            stroke: (bottom: 0.5pt + ui-border),",
			"            [",
			'              #text(font: ("Maple Mono NR NF", "DejaVu Sans Mono"), size: 10pt, fill: if theme-mode == "dark" { rgb("#a0a0a0") } else { rgb("#666666") })[#meta.icon]',
			"              #h(0.6em)",
			'              #text(size: 8.5pt, weight: "bold", fill: if theme-mode == "dark" { rgb("#c0c0c0") } else { rgb("#444444") })[#display]',
			"            ]",
			"          ),",
			"        )",
			"      } else { () },",
			"      block(",
			"        inset: (x: 12pt, y: 10pt),",
			"        width: 100%,",
			"        {",
			"          set text(fill: text-colour, size: 0.9em)",
			"          stack(dir: ttb, spacing: 0.65em, ..bodylines.map(l => l.body))",
			"        }",
			"      )",
			"    )",
			"  )",
			"}",
		}),
	})
end

ls.add_snippets("typst", {
	-- BOILERPLATES & TEMPLATES
	s({ trig = "page", desc = "Note header: import the shared theme and start a note" }, {
		t({ '#import "/templates/theme.typ": *', "" }),
		t({ '#show: theme.with(course: "' }),
		i(1, "COMPXxxx"),
		t({ '")', "", "" }),
		t({ '#set document(title: "' }),
		i(2, "Lecture X — Title"),
		t({ '")', "" }),
		t({ '#let date = "' }),
		i(3, "Week N"),
		t({ '"', "", "" }),
		t({ '#note-title(date, "' }),
		rep(2),
		t({ '")', "", "" }),
		i(0, "Content here..."),
	}),

	s({ trig = "title", desc = "Note title: date + outlined heading" }, {
		t({ '#note-title(date, "' }),
		i(1, "Lecture X — Title"),
		t({ '")' }),
	}),

	-- NOTE BLOCKS & CALLOUTS (With icons, names, and background fills)
	make_callout("note", "Note", "📝", "#3182ce", "Note callout box with blue border, 📝 icon, and background fill"),
	make_callout("info", "Info", "ℹ", "#3182ce", "Info callout box with blue border, ℹ icon, and background fill"),
	make_callout("tip", "Tip", "💡", "#38a169", "Tip callout box with green border, 💡 icon, and background fill"),
	make_callout("warning", "Warning", "⚠", "#dd6b20", "Warning callout box (alias)"),
	make_callout(
		"caution",
		"Caution",
		"🚨",
		"#e53e3e",
		"Caution callout box with red border, 🚨 icon, and background fill"
	),
	make_callout(
		"danger",
		"Danger",
		"🛑",
		"#e53e3e",
		"Danger callout box with red border, 🛑 icon, and background fill"
	),
	make_callout(
		"important",
		"Important",
		"❗",
		"#e53e3e",
		"Important callout box with red border, ❗ icon, and background fill"
	),
	make_callout("definition", "Definition", "📖", "#3182ce", "Definition container box (alias)"),
	make_callout("theorem", "Theorem", "📐", "#38a169", "Theorem container box (alias)"),
	make_callout("lemma", "Lemma", "🧩", "#805ad5", "Lemma container box (alias)"),
	make_callout("corollary", "Corollary", "📎", "#3182ce", "Corollary container box (alias)"),
	make_callout(
		"proposition",
		"Proposition",
		"💡",
		"#3182ce",
		"Proposition container box with blue border, 💡 icon, and background fill"
	),
	make_callout("example", "Example", "✏", "#dd6b20", "Example container box (alias)"),
	make_callout(
		"question",
		"Question",
		"❓",
		"#805ad5",
		"Question container box with purple border, ❓ icon, and background fill"
	),
	make_callout(
		"problem",
		"Problem",
		"❓",
		"#805ad5",
		"Problem container box with purple border, ❓ icon, and background fill"
	),
	make_callout(
		"solution",
		"Solution",
		"💡",
		"#38a169",
		"Solution container box with green border, 💡 icon, and background fill"
	),
	make_callout("remark", "Remark", "💬", "#718096", "Remark container box (alias)"),
	make_callout("takeaway", "Key Takeaway", "📌", "#dd6b20", "Key Takeaway callout box (alias)"),

	-- Proof block
	s({ trig = "proof", desc = "Mathematical proof block (#proof helper)" }, {
		t({ "#proof[", "\t" }),
		i(1, "Proof body..."),
		t({ "", "]" }),
	}),

	-- Modern styled callout alert box with selectable colours
	s({ trig = "callout", desc = "Modern styled callout alert box with icon and background fill" }, {
		t("#block(stroke: (left: 3pt + rgb("),
		c(1, {
			sn(nil, { t('"#3182ce"') }),
			sn(nil, { t('"#38a169"') }),
			sn(nil, { t('"#dd6b20"') }),
			sn(nil, { t('"#e53e3e"') }),
			sn(nil, { t('"#805ad5"') }),
		}),
		t('), rest: 0.5pt + rgb("'),
		c(2, {
			sn(nil, { t("#3182ce35") }),
			sn(nil, { t("#38a16935") }),
			sn(nil, { t("#dd6b2035") }),
			sn(nil, { t("#e53e3e35") }),
			sn(nil, { t("#805ad535") }),
		}),
		t('")), fill: rgb("'),
		c(3, {
			sn(nil, { t("#3182ce15") }),
			sn(nil, { t("#38a16915") }),
			sn(nil, { t("#dd6b2015") }),
			sn(nil, { t("#e53e3e15") }),
			sn(nil, { t("#805ad515") }),
		}),
		t('"), inset: (x: 12pt, y: 10pt), radius: ui-radius, width: 100%)[\n  #text(weight: "bold")['),
		i(4, "ℹ Info: Title"),
		t({ "] \\\n  #v(2pt)\n  " }),
		i(5, "Body content..."),
		t({ "", "]" }),
	}),

	-- CODE BLOCKS (With background and language headers)
	-- Code block show rule to drop into any file
	raw_show_rule("code-show-rule", "Insert #show raw rule for code block background & language header"),
	raw_show_rule("raw-show-rule", "Insert #show raw rule (alias)"),

	-- Code block with filename header banner
	s({ trig = "code-filename", desc = "Code block container with filename header banner" }, {
		t({
			"#block(",
			"  width: 100%,",
			"  radius: ui-radius,",
			"  stroke: 0.5pt + ui-border,",
			"  fill: ui-surface,",
			"  clip: true,",
			"  [",
			"    #block(",
			"      width: 100%,",
			"      fill: ui-surface-raised,",
			"      inset: (x: 12pt, y: 6pt),",
			"      stroke: (bottom: 0.5pt + ui-border),",
			"      [",
			"        #grid(",
			"          columns: (1fr, auto),",
			'          [#text(size: 8.5pt, weight: "bold")[📄 ',
		}),
		i(1, "filename.ext"),
		t({
			"]],",
			'          [#text(size: 7.5pt, weight: "bold")[#upper("',
		}),
		i(2, "lang"),
		t({
			'")]],',
			"        )",
			"      ]",
			"    )",
			"    ```",
		}),
		i(3, "lang"),
		t({ "", "" }),
		i(4),
		t({ "", "    ```", "  ]", ")" }),
	}),

	s({ trig = "code-inline", desc = "Inline monospaced code snippet" }, { t("`"), i(1, "code"), t("`") }),
	s({ trig = "line-numbers", desc = "Toggle line numbers for code blocks from here" }, {
		t("#code-line-numbers.update("),
		c(1, {
			sn(nil, { t("true") }),
			sn(nil, { t("false") }),
		}),
		t(")"),
	}),
	s({ trig = "no-line-numbers", desc = "Code block without line numbers (#noln wrapper)" }, {
		t("#noln[```"),
		i(1, "lang"),
		t({ "", "" }),
		i(0),
		t({ "", "```]" }),
	}),
	s({ trig = "with-line-numbers", desc = "Code block with line numbers (#ln wrapper)" }, {
		t("#ln[```"),
		i(1, "lang"),
		t({ "", "" }),
		i(0),
		t({ "", "```]" }),
	}),
	s({ trig = "code-block", desc = "Code block container with dynamic language identifier" }, {
		t("```"),
		i(1, "lang"),
		t({ "", "" }),
		i(2),
		t({ "", "```" }),
	}),
	s({ trig = "code-fence", desc = "Raw typst interpretation text block container" }, {
		t("```"),
		i(1, "typ"),
		t({ "", "" }),
		i(2),
		t({ "", "```" }),
	}),
	s({ trig = "code-raw", desc = "Raw unhighlighted code text block container" }, {
		t({ "```", "" }),
		i(1),
		t({ "", "```" }),
	}),

	-- Language-specific code blocks
	make_codeblock("code-python", "py", "Code block specified for Python code syntax"),
	make_codeblock("code-sql", "sql", "Code block specified for SQL database query syntax"),
	make_codeblock("code-verilog", "verilog", "Code block specified for Verilog HDL syntax"),
	make_codeblock("code-java", "java", "Code block specified for Java code syntax"),
	make_codeblock("code-c", "c", "Code block specified for C programming language syntax"),
	make_codeblock("code-cpp", "cpp", "Code block specified for C++ programming language syntax"),
	make_codeblock("code-rust", "rust", "Code block specified for Rust code syntax"),
	make_codeblock("code-javascript", "js", "Code block specified for JavaScript code syntax"),
	make_codeblock("code-typescript", "ts", "Code block specified for TypeScript code syntax"),
	make_codeblock("code-shell", "sh", "Code block specified for Shell script programming syntax"),
	make_codeblock("code-bash", "bash", "Code block specified for Bash syntax (alias)"),
	make_codeblock("code-nix", "nix", "Code block specified for Nix package configuration syntax"),
	make_codeblock("code-lua", "lua", "Code block specified for Lua configuration script syntax"),
	make_codeblock("code-typst", "typ", "Code block specified for Typst markup syntax"),
	make_codeblock("code-asm", "asm", "Code block specified for Assembly / RISC-V syntax"),
	make_codeblock("code-html", "html", "Code block specified for HTML markup language syntax"),
	make_codeblock("code-css", "css", "Code block specified for CSS presentational language syntax"),
	make_codeblock("code-json", "json", "Code block specified for JSON data syntax"),
	make_codeblock("code-go", "go", "Code block specified for Go programming syntax"),
	make_codeblock("code-haskell", "hs", "Code block specified for Haskell functional language syntax"),
	make_codeblock("code-php", "php", "Code block specified for PHP code syntax"),
	make_codeblock("code-xml", "xml", "Code block specified for XML markup"),
	make_codeblock("code-csharp", "cs", "Code block specified for C# code syntax"),
	make_codeblock("code-tcl", "tcl", "Code block specified for Tcl script syntax"),
	make_codeblock("code-gradle", "gradle", "Code block specified for Gradle build files"),

	-- LINKS & REFERENCES (With automatic underlines)
	s({ trig = "link", desc = "Hyperlink with custom display text (underlined)" }, {
		t('#link("'),
		i(1, "url"),
		t('")['),
		i(2, "text"),
		t("]"),
	}),
	s({ trig = "url", desc = "Clickable hyperlink URL (underlined)" }, {
		t('#link("'),
		i(1, "url"),
		t('")'),
	}),
	s({ trig = "link-underline", desc = "Insert #show link underline rule" }, {
		t("#show link: underline"),
	}),
	s({ trig = "label", desc = "Cross-reference label" }, { t("<"), i(1, "label"), t(">") }),
	s({ trig = "ref", desc = "Reference a label" }, { t("@"), i(1, "label") }),
	s({ trig = "cite", desc = "Citation" }, { t("#cite(<"), i(1, "key"), t(">)") }),
	s({ trig = "bib", desc = "Bibliography" }, { t('#bibliography("'), i(1, "refs.bib"), t('")') }),

	-- NOTE TAKING ESSENTIALS: STEPS, LISTS, TERMS, BADGES, CARDS
	s({ trig = "step", desc = "Numbered procedure step" }, {
		t("+ *Step "),
		i(1, "1"),
		t(":* "),
		i(2, "Description"),
	}),
	s({ trig = "steps", desc = "3-step procedural checklist" }, {
		t("+ *Step 1:* "),
		i(1, "First step"),
		t({ "", "+ *Step 2:* " }),
		i(2, "Second step"),
		t({ "", "+ *Step 3:* " }),
		i(3, "Third step"),
	}),
	s({ trig = "key-value", desc = "Key-value / term definition pair" }, {
		t("*"),
		i(1, "Term"),
		t(":* "),
		i(2, "Definition"),
		t("\\"),
	}),
	s({ trig = "term", desc = "Term definition with dash separator" }, {
		t("*"),
		i(1, "Term"),
		t("* -- "),
		i(2, "Description"),
	}),
	s({ trig = "badge", desc = "Inline coloured pill badge / tag" }, {
		t('#box(fill: rgb("'),
		c(1, {
			sn(nil, { t("#3182ce20") }),
			sn(nil, { t("#38a16920") }),
			sn(nil, { t("#dd6b2020") }),
			sn(nil, { t("#e53e3e20") }),
			sn(nil, { t("#805ad520") }),
		}),
		t('"), inset: (x: 6pt, y: 2pt), radius: ui-radius-sm)[#text(size: 8pt, weight: "bold", fill: rgb("'),
		c(2, {
			sn(nil, { t("#3182ce") }),
			sn(nil, { t("#38a169") }),
			sn(nil, { t("#dd6b20") }),
			sn(nil, { t("#e53e3e") }),
			sn(nil, { t("#805ad5") }),
		}),
		t('"))['),
		i(3, "TAG"),
		t("]]"),
	}),
	s({ trig = "qa", desc = "Question and Answer study block (#qa helper)" }, {
		t("#qa["),
		i(1, "Question?"),
		t("]["),
		i(2, "Answer"),
		t("]"),
	}),
	s({ trig = "uml-class", desc = "UML class box (#uml-class helper)" }, {
		t({ "#uml-class(", '  "' }),
		i(1, "ClassName"),
		t({ '",', '  fields: ("' }),
		i(2, "- field: Type"),
		t({ '",),', '  methods: ("' }),
		i(3, "+ method(): Type"),
		t({ '",),', ")" }),
	}),
	s({ trig = "card", desc = "Bordered content card container (#card helper)" }, {
		t("#card["),
		i(1, "Content..."),
		t("]"),
	}),
	s({ trig = "box", desc = "Simple padded container box" }, {
		t({ "#box(stroke: 0.5pt + ui-border, inset: (x: 12pt, y: 10pt), radius: ui-radius, width: 100%)[", "\t" }),
		i(1, "Content..."),
		t({ "", "]" }),
	}),
	s({ trig = "todo", desc = "Incomplete checkbox todo list item" }, { t("- [ ] "), i(1) }),
	s({ trig = "done", desc = "Completed checkbox todo list item" }, { t("- [x] "), i(1) }),
	s({ trig = "quote", desc = "Attributed blockquote element" }, {
		t("#quote(attribution: ["),
		i(1, "Author / Source"),
		t({ "])[", "\t" }),
		i(2, "Quote text..."),
		t({ "", "]" }),
	}),
	s({ trig = "date", desc = "Insert current date string" }, {
		d(1, function()
			return sn(nil, { t(os.date("%d %B %Y")) })
		end),
	}),
	s({ trig = "footnote", desc = "Footnote" }, { t("#footnote["), i(1, "note"), t("]") }),
	s(
		{ trig = "table-of-contents", desc = "Table of contents (outline)" },
		{ t({ "#outline(", "  title: [Contents],", "  depth: 2,", ")" }) }
	),
	s({ trig = "divider", desc = "Horizontal divider rule line (alias)" }, {
		t("#line(length: 100%, stroke: 0.6pt + stroke-colour)"),
	}),

	-- TABLES
	make_table(
		"table",
		2,
		2,
		"Header %d",
		"Row %d Cell %d",
		"2-column table with a rounded border that hugs the content"
	),
	make_table(
		"table-3",
		3,
		2,
		"Header %d",
		"Row %d Cell %d",
		"3-column table with a rounded border that hugs the content"
	),
	make_table("table-4", 4, 1, "Col %d", "R%dC%d", "4-column table with a rounded border that hugs the content"),
	make_table("table-5", 5, 2, "Col %d", "R%dC%d", "5-column table with a rounded border that hugs the content"),
	s({ trig = "truthtable", desc = "Digital logic truth table that hugs its content" }, {
		t({
			"#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[",
			"  #table(",
			"    columns: (auto, auto, auto),",
			"    align: center + horizon,",
			"    fill: (col, row) => if row < 2 { ui-surface-raised } else { none },",
			"    inset: (x: 10pt, y: 6pt),",
			"    stroke: none,",
			"    table.cell(colspan: 2)[*INPUT*],",
			"    table.cell(rowspan: 2)[*OUTPUT*],",
			"    [*A*], [*B*],",
			"    table.hline(stroke: 0.5pt + ui-border),",
			"    [0], [0], [",
		}),
		i(1, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [0], [1], [" }),
		i(2, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [1], [0], [" }),
		i(3, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [1], [1], [" }),
		i(4, "1"),
		t({ "],", "  )", "]" }),
	}),
	s({ trig = "truthtable-3", desc = "3-input digital logic truth table that hugs its content" }, {
		t({
			"#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[",
			"  #table(",
			"    columns: (auto, auto, auto, auto),",
			"    align: center + horizon,",
			"    fill: (col, row) => if row < 2 { ui-surface-raised } else { none },",
			"    inset: (x: 10pt, y: 6pt),",
			"    stroke: none,",
			"    table.cell(colspan: 3)[*INPUTS*],",
			"    table.cell(rowspan: 2)[*OUTPUT*],",
			"    [*A*], [*B*], [*C*],",
			"    table.hline(stroke: 0.5pt + ui-border),",
			"    [0], [0], [0], [",
		}),
		i(1, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [0], [0], [1], [" }),
		i(2, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [0], [1], [0], [" }),
		i(3, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [0], [1], [1], [" }),
		i(4, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [1], [0], [0], [" }),
		i(5, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [1], [0], [1], [" }),
		i(6, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [1], [1], [0], [" }),
		i(7, "0"),
		t({ "],", "    table.hline(stroke: 0.5pt + ui-border),", "    [1], [1], [1], [" }),
		i(8, "0"),
		t({ "],", "  )", "]" }),
	}),
	-- FIGURES, MEDIA & DIAGRAMS
	s({ trig = "figure", desc = "Figure block with embedded image and caption" }, {
		t("#figure("),
		t({ "", '  image("' }),
		i(1, "path"),
		t('", width: '),
		i(2, "80%"),
		t("),"),
		t({ "", "  caption: [" }),
		i(3, "Caption"),
		t("],"),
		t({ "", ")" }),
	}),
	s({ trig = "figure-labelled", desc = "Labelled figure for cross-references" }, {
		t({ "#figure(", '  image("' }),
		i(1, "path"),
		t({ '", width: ' }),
		i(2, "80%"),
		t({ "),", "  caption: [" }),
		i(3, "Caption"),
		t({ "],", ") <" }),
		i(4, "fig:label"),
		t(">"),
	}),
	s({ trig = "figure-content", desc = "Captioned figure wrapping content (diagram, table, …)" }, {
		t("#figure(caption: ["),
		i(1, "Caption"),
		t({ "])[", "  " }),
		i(0),
		t({ "", "]" }),
	}),
	s({ trig = "image", desc = "Image insertion element" }, {
		t('#image("'),
		i(1, "path"),
		t('", width: '),
		i(2, "100%"),
		t(")"),
	}),
	s({ trig = "image-grid", desc = "Two figures side-by-side in a grid" }, {
		t({
			"#grid(",
			"  columns: (1fr, 1fr),",
			"  gutter: 12pt,",
			'  figure(image("',
		}),
		i(1, "image1.png"),
		t('"), caption: ['),
		i(2, "Caption 1"),
		t({ "]),", '  figure(image("' }),
		i(3, "image2.png"),
		t('"), caption: ['),
		i(4, "Caption 2"),
		t({ "]),", ")" }),
	}),
	s({ trig = "circuit", desc = "CeTZ & Zap digital logic circuit diagram" }, {
		t({ "#zap.circuit({", "" }),
		t({ "  import zap: *", "" }),
		t({ "  cetz.draw.set-style(zap: zap-theme)", "" }),
		t({ '  node("A", (0, 0.2), label: (content: "A", anchor: "west", distance: 2pt))', "" }),
		t({ '  node("B", (0, -0.2), label: (content: "B", anchor: "west", distance: 2pt))', "" }),
		t({ '  node("C", (2, 0), label: (content: "C", anchor: "east", distance: 2pt))', "" }),
		t({ '  land("and1", (1, 0), label: "AND")', "" }),
		t({ '  wire("A", "and1.in1", anchor: "east")', "" }),
		t({ '  wire("B", "and1.in2", anchor: "east")', "" }),
		t({ '  wire("and1.out", "C", anchor: "west")', "" }),
		t({ "})" }),
	}),
	s({ trig = "cetz", desc = "CeTZ canvas with theme-aware styles and common primitives" }, {
		t({
			"#cetz.canvas({",
			"  import cetz.draw: *",
			"  set-style(stroke: (paint: text-colour, thickness: 0.8pt), fill: none)",
			"  ",
		}),
		i(
			1,
			'// rect((0, 0), (1, 1))\n  // circle((2, 1), radius: 0.5)\n  // line((0, 0), (2, 1), mark: (end: ">"))\n  // content((1, 1), [Label])'
		),
		t({ "", "})" }),
	}),
	s({ trig = "cetz-setup", desc = "Import CeTZ and Zap for diagrams and circuits" }, {
		t({ '#import "@preview/cetz:0.5.2"', '#import "@preview/zap:0.6.0"' }),
	}),
	sym("mermaid-setup", '#import "@preview/mmdr:0.2.2": mermaid', "Import mmdr for Mermaid diagrams"),
	s({ trig = "mermaid-erd", desc = "Mermaid Entity-Relationship Diagram (Database design)" }, {
		t({ "#mermaid(", "" }),
		t({ '  "erDiagram', "" }),
		t({ "  " }),
		i(
			1,
			"ENTITY_ONE {\n    int id PK\n    string name\n  }\n\n"
				.. "  ENTITY_TWO {\n    int id PK\n    int entity_one_id FK\n  }\n\n"
				.. "  ENTITY_ONE ||--o{ ENTITY_TWO : HAS"
		),
		t({ '\n",', "" }),
		t({ "  theme: mmdr-theme,", ")" }),
	}),
	s({ trig = "mermaid-gantt", desc = "Mermaid Gantt chart (Project planning)" }, {
		t({ "#mermaid(", '  "gantt\n  dateFormat YYYY-MM-DD\n  title ' }),
		i(1, "Project Schedule"),
		t({ '\n  section Phase 1\n  Design : 2026-09-01, 7d\n  Coding : 2026-09-08, 14d\n"' }),
		t({ ",", "  theme: mmdr-theme,", ")" }),
	}),
	s({ trig = "mermaid", desc = "Mermaid Diagram wrapper" }, {
		t({ "#mermaid(", "" }),
		t({ '  "', "" }),
		t({ "  " }),
		i(
			1,
			"graph TD\n    A[Start] --> B(Process)\n    B --> C{Decision}\n    C -->|Yes| D[Result 1]\n    C -->|No| E[Result 2]"
		),
		t({ '\n",', "" }),
		t({ "  theme: mmdr-theme,", ")" }),
	}),
	s({ trig = "big-o", desc = "Big-O complexity card (#bigo helper)" }, {
		t({ "#bigo(", '  "' }),
		i(1, "Algorithm / Data Structure Name"),
		t({ '",', "  grid(", "    columns: (1fr, 1fr),", "    [*Time Complexity:*], [*Space Complexity:*],", "" }),
		t({ "    [- Access: $" }),
		i(2, "O(1)"),
		t({ "$], [- Aux Space: $" }),
		i(3, "O(1)"),
		t({ "$],", "" }),
		t({ "    [- Search: $" }),
		i(4, "O(n)"),
		t({ "$], [],", "" }),
		t({ "    [- Insert/Delete: $" }),
		i(5, "O(1)"),
		t({ "$], [],", "" }),
		t({ "  ),", ")" }),
	}),

	-- HEADINGS & LAYOUT
	s({ trig = "h1", desc = "Heading level 1" }, { t("= "), i(1, "Heading") }),
	s({ trig = "h2", desc = "Heading level 2" }, { t("== "), i(1, "Heading") }),
	s({ trig = "h3", desc = "Heading level 3" }, { t("=== "), i(1, "Heading") }),
	s({ trig = "h4", desc = "Heading level 4" }, { t("==== "), i(1, "Heading") }),
	s({ trig = "h5", desc = "Heading level 5" }, { t("===== "), i(1, "Heading") }),
	s({ trig = "columns", desc = "Multi-column layout block" }, {
		t("#columns("),
		i(1, "2"),
		t(")["),
		t({ "", "\t" }),
		i(2),
		t({ "", "]" }),
	}),
	s({ trig = "columns-3", desc = "3-column layout block" }, {
		t("#columns(3)["),
		t({ "", "\t" }),
		i(1),
		t({ "", "]" }),
	}),
	sym("column-break", "#colbreak()", "Column break"),
	sym("page-break", "#pagebreak()", "Page break"),
	s({ trig = "align", desc = "Content alignment block (centre, left, right)" }, {
		t("#align("),
		c(1, {
			sn(nil, { t("center") }),
			sn(nil, { t("left") }),
			sn(nil, { t("right") }),
		}),
		t(")["),
		t({ "", "\t" }),
		i(2),
		t({ "", "]" }),
	}),
	s({ trig = "grid", desc = "2-column grid layout" }, {
		t({ "#grid(", "  columns: (1fr, 1fr),", "  gutter: 10pt,", "  [" }),
		i(1, "Left column"),
		t({ "],", "  [" }),
		i(2, "Right column"),
		t({ "],", ")" }),
	}),

	-- TEXT FORMATTING
	wrap("bold", "*", "*", "Bold text format"),
	wrap("italic", "_", "_", "Italic text format"),
	wrap("strikethrough", "#strike[", "]", "Strikethrough text format"),
	wrap("highlight", "#highlight[", "]", "Highlight text background"),
	wrap("smallcaps", "#smallcaps[", "]", "Small caps text format"),
	wrap("superscript", "#super[", "]", "Superscript text"),
	wrap("subscript", "#sub[", "]", "Subscript text"),

	-- MATHEMATICS
	wrap("$", "$", "$", "Inline math block"),
	wrap("$$", "$ ", " $", "Display math block"),
	s({ trig = "equation", desc = "Multi-line block equation syntax" }, {
		t({ "$ " }),
		i(1),
		t({ " \\", "  " }),
		i(2),
		t({ " \\", "  " }),
		i(3),
		t({ " $" }),
	}),
	s({ trig = "equation-align", desc = "Aligned block equation structure using ampersand relations" }, {
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
	wrap("sqrt", "sqrt(", ")", "Mathematical square root radical function"),
	s(
		{ trig = "root", desc = "Mathematical nth-order root function" },
		{ t("root("), i(1, "n"), t(", "), i(2, "x"), t(")") }
	),
	wrap("abs", "|", "|", "Absolute value bracket wrapper"),
	wrap("norm", "||", "||", "Mathematical norm bracket wrapper"),
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
	wrap("ceil", "ceil(", ")", "Mathematical ceiling rounding bracket function"),
	wrap("floor", "floor(", ")", "Mathematical floor rounding bracket function"),
	wrap("cases", "cases(", ")", "Piecewise math function cases container"),

	-- Matrices & Vectors
	wrap("vec", "vec(", ")", "Vector column array template"),
	wrap("mat", "mat(", ")", "Generic structural matrix template"),
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
	wrap("det", "det ", "", "Matrix determinant operator prefix"),
	wrap("trace", "tr ", "", "Matrix trace operator prefix"),
	wrap("transpose", "", "^T", "Matrix transpose mathematical superscript"),
	wrap("inv", "", "^(-1)", "Matrix inverse mathematical power superscript"),

	-- Accents & Brackets
	wrap("conj", "conj(", ")", "Complex conjugate modifier function"),
	wrap("hat", "hat(", ")", "Hat accent mathematical symbol modifier"),
	wrap("bar", "overline(", ")", "Overline bar accent mathematical symbol modifier"),
	wrap("tilde", "tilde(", ")", "Tilde accent mathematical symbol modifier"),
	wrap("dot", "dot(", ")", "Single dot accent mathematical symbol modifier"),
	wrap("ddot", "dot.double(", ")", "Double dot accent mathematical symbol modifier"),
	wrap("delimiters", "lr(", ")", "Dynamic sizing left-right parentheses wrapper"),
	wrap("delimiters-bracket", "lr([", "])", "Dynamic sizing left-right square brackets wrapper"),
	wrap("delimiters-curly", "lr({", "})", "Dynamic sizing left-right curly braces wrapper"),
	wrap("set", "{ ", " }", "Mathematical set notation"),
	s(
		{ trig = "set-builder", desc = "Set builder notation with condition" },
		{ t("{ "), i(1, "x"), t(" in "), i(2, "S"), t(" : "), i(3, "P(x)"), t(" }") }
	),

	-- Math Symbols, Relations & Arrows
	sym("infinity", "infinity", "Infinity mathematical symbol"),
	sym("nabla", "nabla", "Nabla gradient mathematical operator"),
	sym("arrow", "arrow", "Standard math relation arrow direction"),
	sym("arrow-right", "arrow.r", "Rightward pointing relation arrow"),
	sym("arrow-left", "arrow.l", "Leftward pointing relation arrow"),
	sym("arrow-up", "arrow.t", "Upward pointing relation arrow"),
	sym("arrow-down", "arrow.b", "Downward pointing relation arrow"),
	sym("iff", "<==>", "If and only if logical equivalence arrow"),
	sym("==>", "==>", "Logical implication rightward relation arrow"),
	sym("therefore", "therefore", "Therefore logical conclusion symbol"),
	sym("because", "because", "Because logical explanation symbol"),
	sym("forall", "forall", "For all universal quantifier symbol"),
	sym("exists", "exists", "Exists existential quantifier symbol"),
	sym("elem", "in", "Element of set membership symbol"),
	sym("notin", "in.not", "Not an element of set membership negation symbol"),
	sym("subset", "subset", "Subset inclusion operation relation symbol"),
	sym("supset", "supset", "Superset relation symbol"),
	sym("subset-equal", "subset.eq", "Subset-or-equal relation symbol"),
	sym("superset-equal", "supset.eq", "Superset-or-equal relation symbol"),
	sym("cup", "union", "Union set operation symbol"),
	sym("cap", "intersection", "Intersection set operation symbol"),
	sym("empty", "nothing", "Empty set null space placeholder symbol"),
	sym("neq", "!=", "Not equal relation symbol"),
	sym("leq", "<=", "Less than or equal relation symbol"),
	sym("geq", ">=", "Greater than or equal relation symbol"),
	sym("approx", "approx", "Approximately equal relation symbol"),
	sym("times", "times", "Multiplication cross symbol"),
	sym("cdot", "dot.c", "Centre dot multiplication symbol"),

	-- Number sets (Blackboard Bold)
	sym("real", "RR", "Set of real numbers blackboard bold identifier"),
	sym("natural", "NN", "Set of natural numbers blackboard bold identifier"),
	sym("integer", "ZZ", "Set of integers blackboard bold identifier"),
	sym("rational", "QQ", "Set of rational numbers blackboard bold identifier"),
	sym("complex", "CC", "Set of complex numbers blackboard bold identifier"),

	-- Greek lowercase letters
	sym("alpha", "alpha", "Greek lowercase letter alpha"),
	sym("beta", "beta", "Greek lowercase letter beta"),
	sym("gamma", "gamma", "Greek lowercase letter gamma"),
	sym("delta", "delta", "Greek lowercase letter delta"),
	sym("epsilon", "epsilon", "Greek lowercase letter epsilon"),
	sym("theta", "theta", "Greek lowercase letter theta"),
	sym("lambda", "lambda", "Greek lowercase letter lambda"),
	sym("mu", "mu", "Greek lowercase letter mu"),
	sym("pi", "pi", "Greek lowercase letter pi"),
	sym("sigma", "sigma", "Greek lowercase letter sigma"),
	sym("omega", "omega", "Greek lowercase letter omega"),
	sym("phi", "phi", "Greek lowercase letter phi"),
	sym("psi", "psi", "Greek lowercase letter psi"),
	sym("rho", "rho", "Greek lowercase letter rho"),
	sym("tau", "tau", "Greek lowercase letter tau"),
	sym("zeta", "zeta", "Greek lowercase letter zeta"),
	sym("eta", "eta", "Greek lowercase letter eta"),
	sym("iota", "iota", "Greek lowercase letter iota"),
	sym("kappa", "kappa", "Greek lowercase letter kappa"),
	sym("nu", "nu", "Greek lowercase letter nu"),
	sym("xi", "xi", "Greek lowercase letter xi"),
	sym("chi", "chi", "Greek lowercase letter chi"),
	sym("upsilon", "upsilon", "Greek lowercase letter upsilon"),
	sym("omicron", "omicron", "Greek lowercase letter omicron"),
})
