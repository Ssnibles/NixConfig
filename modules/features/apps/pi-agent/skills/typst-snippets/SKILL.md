---
name: typst-snippets
description: The user's canonical Typst (.typ) document conventions, derived from their personal LuaSnip snippet library. Use whenever writing, generating, or editing Typst markup so callout boxes, code blocks, tables, page setup, math, diagrams, and text formatting match the established house style. Load this before emitting any Typst unless the user explicitly asks for a different style.
---

# Typst snippets and house style

When you write or edit Typst for this user, **reproduce the output of their canonical
snippets** instead of inventing new markup or styling. If a snippet exists for a
construct, use its exact expansion (same helper functions, colors, dimensions, and
show rules). Only deviate when the user explicitly asks for something different.

When the document is lecture or course material, also load the `lecture-notes`
skill: it defines **what the notes should contain** (explanations, examples,
connections, self-tests) so they are a learning resource rather than a re-typed
copy of the slides. This skill only covers **how** it should look.

> **Before writing or restructuring a document, read
> `references/document-conventions.md`.** It is the full house-style checklist:
> structure, metadata, content-to-snippet mapping, math, code, diagrams,
> language, continuity, and the things not to do.

The bundled file `references/typst.lua` (in this skill directory) is the **source of
truth**. It is a LuaSnip library (`ls.add_snippets("typst", { ... })`) copied from the
user's Neovim config. Read it whenever you need an exact template, and mirror it
verbatim rather than guessing.

Useful ways to inspect it:

```bash
# List every trigger with its line number
grep -n 'trig = "' <skill-dir>/references/typst.lua

# List descriptions
grep -n 'desc = "' <skill-dir>/references/typst.lua

# Read one snippet (e.g. the "page" boilerplate), then step forward
grep -n '"page"' <skill-dir>/references/typst.lua
```

Snippets built through the helpers `make_callout`, `make_codeblock`, and `wrap`
do not have the trigger text inline; their triggers are the first string argument
of each helper call. Grep for `make_callout(`, `make_codeblock(`, and `wrap(` too.

## Reading the snippet library

`references/typst.lua` is LuaSnip, not raw Typst. To reproduce a snippet, expand
its nodes **in order, with no separator between them**:

| Node | Meaning | Expansion |
|---|---|---|
| `t("…")` / `t({ "a", "b" })` | text | the string, or its lines joined by `\n` (an empty `""` is a blank line) |
| `i(n, default)` | tab stop | the `default` text (or `""`), inserted exactly where it appears |
| `c(n, { sn(…), … })` | choice | the **first** choice |
| `sn(n, { … })` | nested snippet | expand its nodes in place |

A snippet is `s({ trig = "…", desc = "…" }, { nodes… })`. So
`t('#let theme = "')` + `c(1, { sn(nil, { t("dark") }), … })` + `t('"')` becomes
`#let theme = "dark"`.

For the `page` preamble you do **not** need to expand by hand: copy
`references/page-preamble.typ`, which is the exact expanded output of the `page`
snippet.

For a worked body in this style, read `references/example.typ`: a definition
callout, a Big-O card, display math, a code block, a table, and a themed diagram
in one place.

## Always start from the page preamble

Most snippets assume the document preamble defined by the `page` snippet. It sets
the variables `theme` (`"dark"`/`"light"`), `page-type` (`"notes"`/`"lecture"`),
`course`, `date`, `bg-color`, `text-color`, `stroke-color`, and the font tokens
`font-sans`/`font-serif`, and installs the `#show` rules for headings, links,
block/inline `raw`, and the title block.

It also defines the shared font and UI design tokens used throughout, so all
containers and typography stay visually consistent:

- `font-sans` — the **body** font (`"SF Pro Text"`). Set globally by
  `#set text(font: font-sans)`; it applies to paragraphs, lists, tables, callout
  content, and the footer page number.
- `font-serif` — the **display** font (`"New Computer Modern"`). Used only by
  headings, the title block, and the running header/footer, via
  `#show heading: set text(font: font-serif)` plus explicit `font: font-serif`
  overrides. Math is unaffected (Typst keeps `New Computer Modern Math`).
- `ui-radius = 6pt` — corner radius for every block (callouts, cards, code blocks,
  tables). `ui-radius-sm = 3pt` for inline pills and inline code.
- `ui-border` — subtle border color (`#2e2f38` dark / `#e2e2e8` light), used instead
  of the bright `stroke-color` for container borders.
- `ui-surface` — raised panel fill for cards and code blocks.
- `ui-surface-raised` — header/row fill for code headers and table headers.

**Typography is role-split:** normal prose is sans-serif (`font-sans`), while
headings and heading-like furniture are serif (`font-serif`). Never pass a literal
family name to `font:`; always use the two tokens so the split stays consistent.

**Every block rounds all four corners** (no more one-sided radii) and uses the
`ui-*` tokens rather than ad-hoc colors. Callouts keep their colored left accent
bar, but now share the same 6pt radius, 0.5pt base border, and 12pt/10pt inset as
the other containers.

**If a Typst document does not already contain this preamble, insert it first** by
copying `references/page-preamble.typ` verbatim. Callouts, cards, boxes, tables,
code blocks, `cbf`, and `bigo` reference the `theme`/`ui-*` variables, so they
render incorrectly (or fail) without it.

## Palette

Reuse these exact colors from the snippets:

| Role     | Hex       | Used by                                     |
|----------|-----------|---------------------------------------------|
| blue     | `#3182ce` | note, info, definition, corollary, table headers |
| green    | `#38a169` | tip, theorem, solution                      |
| orange   | `#dd6b20` | warning, example, key takeaway              |
| red      | `#e53e3e` | caution, danger, important                  |
| purple   | `#805ad5` | lemma, question, problem                    |
| grey     | `#718096` | remark, proof                               |

Accent surfaces use a translucent variant of the accent: `rgb("<hex>35")` for the
faint border and `rgb("<hex>15")` for the fill.

### Surfaces and shape

| Token               | Dark      | Light     | Used by                          |
|---------------------|-----------|-----------|----------------------------------|
| `ui-border`         | `#2e2f38` | `#e2e2e8` | every container border           |
| `ui-surface`        | `#1f1f26` | `#f7f7fa` | card and code block fill         |
| `ui-surface-raised` | `#17171c` | `#efeff3` | code block / table header        |
| `ui-radius`         | `6pt`     | `6pt`     | all block corners                |
| `ui-radius-sm`      | `3pt`     | `3pt`     | badges and inline code           |

## Callout boxes (canonical pattern)

Every callout expands to this shape. Substitute the colour, icon, and title from
the table below:

```typst
#block(
	width: 100%,
	stroke: (left: 3pt + rgb("#3182ce"), rest: 0.5pt + rgb("#3182ce35")),
	fill: rgb("#3182ce15"),
	inset: (x: 12pt, y: 10pt),
	radius: ui-radius,
	[
		#text(weight: "bold", fill: rgb("#3182ce"))[📝 Note: Title] \
		#v(2pt)
		Content...
	]
)
```

| Trigger | Colour | Icon | Title |
|---|---|---|---|
| `note` | blue `#3182ce` | 📝 | Note |
| `info` | blue | ℹ | Info |
| `tip` | green `#38a169` | 💡 | Tip |
| `warn` / `warning` | orange `#dd6b20` | ⚠ | Warning |
| `caution` | red `#e53e3e` | 🚨 | Caution |
| `danger` | red | 🛑 | Danger |
| `important` | red | ❗ | Important |
| `def` / `definition` | blue | 📖 | Definition |
| `thm` / `theorem` | green | 📐 | Theorem |
| `lem` / `lemma` | purple `#805ad5` | 🧩 | Lemma |
| `cor` / `corollary` | blue | 📎 | Corollary |
| `prop` | blue | 💡 | Proposition |
| `ex` / `example` | orange | ✏ | Example |
| `question` | purple | ❓ | Question |
| `prob` | purple | ❓ | Problem |
| `sol` | green | 💡 | Solution |
| `rem` / `remark` | grey `#718096` | 💬 | Remark |
| `key` / `takeaway` | orange | 📌 | Key Takeaway |

`proof` is a separate grey block (see below). The generic `callout` snippet is the
same pattern with a colour `choice_node` (blue → green → orange → red → purple).

## Proof

```
#block(
	width: 100%,
	stroke: (left: 3pt + rgb("#718096"), rest: 0.5pt + rgb("#71809635")),
	fill: rgb("#71809612"),
	inset: (x: 12pt, y: 10pt),
	radius: ui-radius,
	[
		#text(weight: "bold", fill: rgb("#718096"))[∎ Proof:] \
		#v(2pt)
		Proof body... #h(1fr) $square$
	]
)
```

## Code blocks and raw styling

- The `page` preamble already installs all shared code styling: the `lang-meta` map,
  the `#show raw.where(block: true)` rule (background, radius, stroke, header bar
  with Nerd Font devicon + filename/lang), **and** the
  `#show raw.where(block: false)` inline-code rule. Do not re-insert any of them.
- `codeshow` / `rawshow` are only for documents that do **not** use the `page`
  preamble; they insert the `lang-meta` map plus the block `raw` rule. Do not apply
  them on top of `page` — the rules are redundant. `codeshow` used to also re-emit
  the inline rule, which applied twice and produced a double border on inline code.
- `cb <lang>` / `raw` / ` ``` ` and the language-specific `cbpy`, `cbsql`, `cbv`/`cbverilog`,
  `cbjava`, `cbc`, `cbcpp`, `cbrs`, `cbjs`, `cbts`, `cbsh`/`cbbash`, `cbnix`, `cblua`,
  `cbtyp`, `cbasm`, `cbhtml`, `cbcss`, `cbjson`, `cbgo`, `cbhs` produce fenced code
  blocks. Put the filename on the first line when the header should show it (the
  show rule treats a first line without spaces as a filename).
- `cbf` builds the standalone filename-banner container by hand; like the show
  rule it uses `ui-radius`, `ui-border`, `ui-surface`, `ui-surface-raised`, and a
  12pt/6pt header inset.
- `ic` is inline code: `` `code` `` (a `ui-surface` box with `ui-radius-sm` and a
  `0.5pt + ui-border` stroke).

Because the `page` preamble installs the block `raw` rule, fenced code in a
page-based document renders with the header bar automatically.

## Tables

The tables are now rounded cards with a subtle grid instead of a full bright
box. `tbl` (2 columns), `tbl3` (3 columns), `tbl4` (4 columns) all expand to this
shape (substituting the column list and cell count):

```typst
#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border, width: 100%)[
  #table(
    columns: (1fr, 1fr),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => if y == 0 { (bottom: 0.5pt + ui-border) } else { none },
    [*Header 1*], [*Header 2*],
    [Row 1 Cell 1], [Row 1 Cell 2],
    [Row 2 Cell 1], [Row 2 Cell 2],
  )
]
```

`truthtable` uses the same wrapper with `align: center + horizon`, a header fill
of `if row < 2 { ui-surface-raised } else { none }`, `stroke: none`, and a
full-width `table.hline(stroke: 0.5pt + ui-border)` after the `A`/`B` row. Use
`table.hline` here rather than a per-cell stroke function: the row-spanned
`OUTPUT` cell shifts the per-cell `y` indices and truncates the separator.

Keep the wrapper, neutral header fill, and `ui-border` separator exactly as
templated; do not reintroduce `stroke-color` or the accent-tinted header.

## Figures and diagrams

- `fig` → `#figure(image("path", width: 80%), caption: [...])`.
- `img` → `#image("path", width: 100%)`.
- `gridimg` → two captioned figures side by side in `#grid(columns: (1fr, 1fr), gutter: 12pt, ...)`.
- `erd`, `gantt`, `mmd` → `#mermaid("...")` wrappers for ER, Gantt, and generic diagrams.
- `circuit` → `#zap.circuit({ import zap: *; ... })` CeTZ/Zap IEEE logic circuit.
- `cetz` → `#cetz.canvas({ import cetz.draw: *; ... })`.
- `bigo` → the blue "⚡ Big-O" complexity card, using the same left-accent
  structure as a callout (`left: 3pt + rgb("#3182ce")`, `rest: 0.5pt + rgb("#3182ce35")`,
  `fill: rgb("#3182ce15")`, `radius: ui-radius`) plus a bold title and 2-column grid.

Diagrams are the number-one source of failed compiles and are **composed, not
copied**. Before drawing one, read `references/diagrams.md` for the import lines,
the tool-choice table, the Zap/CeTZ/mmdr templates, and the debugging checklist.
The essentials: import the package at the top of the file, and compile after
every diagram you add.

## Headings and layout

- `h1`…`h5` → `= `…`===== ` (these feed the `page` show rules).
- `col`/`cols` (2-column), `col3` (3-column), `colbreak`, `pagebreak`.
- `align` → `#align(center|left|right)[...]`.
- `grid` → 2-column `#grid` with `gutter: 10pt`.

## Text formatting

`bf` `*bold*`, `it` `_italic_`, `st` `#strike[...]`, `hl` `#highlight[...]`,
`sc` `#smallcaps[...]`, `sup` `#super[...]`, `sub` `#sub[...]`.

## Note-taking elements

- `step` / `steps` → numbered `+ *Step N:*` items.
- `kv` / `term` → bold term + definition.
- `badge` → inline colored pill (`#box(fill: rgb("<hex>20"), inset: (x: 6pt, y: 2pt), radius: ui-radius-sm)[...]`).
- `qa` → `*Q:* ... \\ *A:* ...`.
- `card` → `#block(width: 100%, stroke: 0.5pt + ui-border, fill: ui-surface, inset: (x: 12pt, y: 10pt), radius: ui-radius)[...]`.
- `box` → `#box(stroke: 0.5pt + ui-border, inset: (x: 12pt, y: 10pt), radius: ui-radius, width: 100%)[...]`.
- `todo` / `done` → `- [ ]` / `- [x]`.
- `quote` → `#quote(attribution: [...])[...]`.
- `hr` / `divider` → `#line(length: 100%, stroke: 0.6pt + stroke-color)`.
- `date` → the current date `dd Month YYYY`.

## Links

`lnk` → `#link("url")[text]`, `url` → `#link("url")`, `linkshow` → `#show link: underline`.

## Mathematics

Inline math is `$...$`; display math is `$ ... $` on its own line. Use **Typst math
names, never LaTeX**, and define each symbol on first use. The full trigger →
expansion tables (delimiters, operators, matrices, relations, sets, Greek letters)
are in `references/math.md`.

## Trigger quick index

Boilerplate: `page`
Callouts: `note` `info` `tip` `warn` `warning` `caution` `danger` `important`
`def` `definition` `thm` `theorem` `lem` `lemma` `cor` `corollary` `prop` `ex`
`example` `question` `prob` `sol` `rem` `remark` `key` `takeaway` `proof` `callout`
Code: `codeshow` `rawshow` `cbf` `ic` `cb` ` ``` ` `raw` and `cbpy` `cbsql` `cbv`
`cbverilog` `cbjava` `cbc` `cbcpp` `cbrs` `cbjs` `cbts` `cbsh` `cbbash` `cbnix`
`cblua` `cbtyp` `cbasm` `cbhtml` `cbcss` `cbjson` `cbgo` `cbhs`
Notes/lists: `step` `steps` `kv` `term` `badge` `qa` `card` `box` `todo` `done`
`quote` `date` `hr` `divider`
Tables: `tbl` `tbl3` `tbl4` `truthtable`
Figures/diagrams: `fig` `img` `gridimg` `circuit` `cetz` `erd` `gantt` `mmd`
`cetzsetup` `mmdsetup` `bigo`
Layout: `h1` `h2` `h3` `h4` `h5` `col` `cols` `col3` `colbreak` `pagebreak` `align` `grid`
Links: `lnk` `url` `linkshow`
Formatting: `bf` `it` `st` `hl` `sc` `sup` `sub`
Math: `$` `$$` `eq` `eqalign` `frac` `sum` `prod` `int` `lim` `sqrt` `root` `abs`
`norm` `pdiff` `diff` `binom` `ceil` `floor` `cases` `vec` `mat` `mat2` `mat3` `det`
`trace` `transpose` `inv` `conj` `hat` `bar` `tilde` `dot` `ddot` `lr` `lrb` `lrc`
`set` `setb` `inff` `nab` `arr` `rarr` `larr` `uarr` `darr` `iff` `==>` `therefore`
`because` `forall` `exists` `elem` `notin` `subs` `cup` `cap` `empty` `neq` `leq`
`geq` `approx` `times` `cdot` `RR` `add` `NN` `ZZ` `QQ` `CC` and the Greek triggers
`aa` `bb` `gg` `dd` `ee` `th` `ll` `mm` `pp` `ss` `oo` `ph` `ps` `rh` `ta`

## Maintenance

`references/typst.lua` is copied at build time from
`modules/features/nvim-src/lua/snippets/typst.lua`, which is the single source of
truth. Edit that file (not the copy) when snippets change; the bundled copy
refreshes on the next rebuild.

`references/page-preamble.typ` is the expanded `page` snippet; `references/diagrams.md`,
`references/math.md`, and `references/example.typ` are hand-written. If the `page`
snippet changes, regenerate `page-preamble.typ` and keep the hand-written
references in sync.
