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
copy of the slides. When the source is a *test, exam or practice paper*, load the
`test-notes` skill instead: it defines the per-question worked-answer format
(verbatim question, correct answer, reasoning, distractor analysis). This skill
only covers **how** it should look.

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

For the note header you do **not** need to expand by hand: copy
`references/page-preamble.typ`, which is the exact output of the `page` snippet.

For a worked body in this style, read `references/example.typ`: a definition
callout, a Big-O card, display math, a code block, a table, and a themed diagram
in one place.

## Always start from the shared theme

Notes do **not** inline a preamble. All styling lives in one file — `theme.typ`
(`templates/theme.typ` in a notes repo; bundled here as `references/theme.typ`) —
and a note imports it:

```typst
#import "/templates/theme.typ": *
#show: theme.with(course: "COMPXxxx")

#set document(title: "Lecture X — Title")
#let date = "Week N"

#note-title(date, "Lecture X — Title")
```

Compile with the repository as the Typst root, e.g.
`typst compile --root ~/Uni "<note>.typ"` — the `/templates/theme.typ` import is
root-relative. `references/page-preamble.typ` is exactly this header.

`theme.with(...)` installs the page setup and the `#show` rules for headings,
links, block/inline `code-raw` and figure captions, and defines the tokens below.

It also defines the shared font and UI design tokens used throughout, so all
containers and typography stay visually consistent:

- `font-sans` — the **body** font (`"SF Pro Text"`). Set globally by
  `#set text(font: font-sans)`; it applies to paragraphs, lists, tables, callout
  content, and the footer page number.
- `font-serif` — the **display** font (`"New Computer Modern"`). Used only by
  headings, the title block, and the running header/footer, via
  `#show heading: set text(font: font-serif)` plus explicit `font: font-serif`
  overrides. Math is unaffected (Typst keeps `New Computer Modern Math`).
- `font-mono` — the **code** font (`"JetBrainsMono NF"`), used by the code-block
  header icon. Each of the three tokens is a **fallback list** (for example
  `("SF Pro Text", "Inter", "DejaVu Sans")`), so a font that is missing on a given
  machine degrades to the next one instead of erroring. Never hardcode a family
  name; use `font-sans` / `font-serif` / `font-mono`.
- `ui-radius = 6pt` — corner radius for every block (callouts, cards, code blocks,
  tables). `ui-radius-sm = 3pt` for inline pills and inline code.
- `ui-border` — subtle border color (`#2e2f38` dark / `#e2e2e8` light), used instead
  of the bright `stroke-color` for container borders.
- `ui-surface` — raised panel fill for cards and code blocks.
- `ui-surface-raised` — header/row fill for code headers and table headers.

**Title layout:** `#note-title(date, title)` renders the date top-left and the
title centred beneath it (hyphenation disabled, so a long title wraps to whole
words). The title is a real level-1 heading, so it feeds the outline and PDF
bookmarks for free — use it (or the `title` snippet) rather than hand-copying the
block.

**Page type:** pass `page-type: "notes"` (the default) for self-study notes — a
running header on every page — or `page-type: "lecture"` for a lecture handout
with a numbered footer. Pick one and keep it for the whole document; do not mix.

**Typography is role-split:** normal prose is sans-serif (`font-sans`), while
headings and heading-like furniture are serif (`font-serif`). Never pass a literal
family name to `font:`; always use the two tokens so the split stays consistent.

**Every block rounds all four corners** (no more one-sided radii) and uses the
`ui-*` tokens rather than ad-hoc colors. Callouts keep their colored left accent
bar, but now share the same 6pt radius, 0.5pt base border, and 12pt/10pt inset as
the other containers.

**If a notes repo does not yet have `templates/theme.typ`, create it first** by
copying the bundled `references/theme.typ`. Callouts, cards, boxes, tables, code
blocks, `code-filename` and `big-o` reference the `theme`/`ui-*` bindings, so they render
incorrectly (or fail) without the theme in scope.

**A project-local theme wins.** If the repository ships its own
`templates/theme.typ`, treat that as the source of truth and ignore the bundled
copy. In this repo the theme lives at `~/Uni/templates/theme.typ`; read
`~/Uni/AGENTS.md` for the note shape.

## Convenience helpers (preferred over inline blocks)

The theme defines these functions; **call them instead of writing the raw
`#block(...)` markup**, so every callout, card, and Q&A block stays consistent.
They arrive with `#import "/templates/theme.typ": *`, and the `title` snippet
emits a `#note-title(...)` call.

```typst
#callout(icon, title, color, body)         // colored left-accent callout
#card(body)                                // neutral bordered card
#qa(question, answer)                      // stacked Q + bold-A retrieval pair
#uml-class(name, fields: (), methods: ())  // UML class box
#proof(body)                               // grey proof block (∎ + QED)
#bigo(title, body)                         // blue "⚡ Big-O" complexity card
#keep-together(body)                       // keep a block on one page when it fits
#note-title(date, title)                   // date + outlined title heading
```

```typst
#callout("📖", "Definition — injection:", "#3182ce")[User data is treated as code.]
#card[*Big picture.* Every note answers one question end to end.]
#qa[Why prepared statements?][Placeholders keep data and SQL separate.]
#uml-class("Book", fields: ([title: Str], [author: Str]), methods: ([borrow()],))
#note-title("Week 10, Lecture 2", "Lecture 10.2 — XML and XPath")
```

`#callout`'s `color` is the bare palette hex (e.g. `"#3182ce"`); the helper derives
the `35` border and `15` fill automatically. `#uml-class` expects **arrays** for
`fields` and `methods` (`([a], [b])`), because it spreads them into a `stack`.
`#note-title` is the single source of the title block.

**Blocks keep together on one page.** The theme wraps tables, code blocks,
`#callout`, `#card`, `#proof` and `#bigo` in `keep-together(...)`. It measures the
block and, when it does not fit in the space left on the page, moves the whole block
to the next page rather than splitting it and leaving one or two orphan rows/lines
behind. A block that is genuinely taller than a page still breaks normally. Wrap
any other content yourself when it must not split: `#keep-together[...]`.

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

The callout snippets emit the theme's `#callout(icon, title, colour, body)`
helper — e.g. `#callout("📝", "Note:", "#3182ce")[Content...]` — and the helper
renders this shape. Substitute the icon, title, and colour from the table below:

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
| `warning` | orange `#dd6b20` | ⚠ | Warning |
| `caution` | red `#e53e3e` | 🚨 | Caution |
| `danger` | red | 🛑 | Danger |
| `important` | red | ❗ | Important |
| `definition` | blue | 📖 | Definition |
| `theorem` | green | 📐 | Theorem |
| `lemma` | purple `#805ad5` | 🧩 | Lemma |
| `corollary` | blue | 📎 | Corollary |
| `proposition` | blue | 💡 | Proposition |
| `example` | orange | ✏ | Example |
| `question` | purple | ❓ | Question |
| `problem` | purple | ❓ | Problem |
| `solution` | green | 💡 | Solution |
| `remark` | grey `#718096` | 💬 | Remark |
| `takeaway` | orange | 📌 | Key Takeaway |

`proof` is a separate grey block (see below). The generic `callout` snippet is the
same pattern with a colour `choice_node` (blue → green → orange → red → purple).

## Proof

The `proof` snippet emits the theme's `#proof(body)` helper, which renders the
grey `∎ Proof:` block with a QED square:

```typst
#proof[
  Suppose $n$ is even, so $n = 2k$ …
]
```

Algorithm cost uses the `big-o` snippet → `#bigo(title, body)` (the blue
"⚡ Big-O" card), e.g. `#bigo("Binary search", grid(columns: (1fr, 1fr), …))`.

## Code blocks and raw styling

- The theme installs all shared code styling with **one** `#show raw:`
  rule that branches on `it.block`: block code gets the card + header bar (Nerd Font
  devicon + filename/lang), inline code gets the rounded `ui-surface` box. Keeping
  it a single rule is deliberate — two separate `code-raw` show rules stack and produce a
  **double border** on inline code. Do not split it, and do not re-insert any of it.
- `code-show-rule` / `raw-show-rule` are only for documents that do **not** use the theme;
  they insert the `lang-meta` map plus a block `code-raw` rule. Do not apply them on top
  of the theme — the rules are redundant and would double the code styling.
- `cb <lang>` / `code-raw` / ` ``` ` and the language-specific `code-python`, `code-sql`, `code-verilog`/`code-verilog`,
  `code-java`, `code-c`, `code-cpp`, `code-rust`, `code-javascript`, `code-typescript`, `code-shell`/`code-bash`, `code-nix`, `code-lua`,
  `code-typst`, `code-asm`, `code-html`, `code-css`, `code-json`, `code-go`, `code-haskell`, `code-php`, `code-xml`,
  `code-csharp`, `code-tcl`, `code-gradle` produce fenced code blocks. Put the filename on the
  first line when the header should show it: the show rule treats a first line as
  a filename only if it *looks* like one (`main.rs`, `schema.sql`) — code such as
  `<?php` or `<div>` is left alone. The `lang-meta` map covers `py`, `js`, `ts`,
  `rust`, `c`/`cpp`, `java`, `go`, `sh`/`bash`, `html`, `css`, `nix`, `lua`, `sql`,
  `json`, `yaml`, `md`, `asm`, `hs`, `php`, `xml`, `verilog`/`v`, `tcl`, `gradle`,
  `cs`/`csharp`, `http`, `txt`, `toml`, `dockerfile`, `kotlin`, `swift`, and `r`;
  anything else falls back to a generic icon.
- **Line numbers are on by default** (a muted gutter aligned with the code).
  Toggle a whole document with `#code-line-numbers.update(false)` / `(true)` (the
  `line-numbers` snippet). For one block, use the `no-line-numbers` / `with-line-numbers` snippets, which wrap a
  fresh fence: `#noln[```py … ```]` turns numbers off for that block, `#ln[…]`
  forces them on.
- **PHP highlights even without `<?php`.** Typst only highlights inside PHP's open
  tag, so the theme re-injects a hidden opener when a `php` block lacks one. Write
  the snippet the way you want it shown; don't add `<?php` just for colour.
- `code-filename` builds the standalone filename-banner container by hand; like the show
  rule it uses `ui-radius`, `ui-border`, `ui-surface`, `ui-surface-raised`, and a
  12pt/6pt header inset.
- `code-inline` is inline code: `` `code` `` (a `ui-surface` box with `ui-radius-sm` and a
  `0.5pt + ui-border` stroke).

Because the theme installs the block `code-raw` rule, fenced code in a themed document
renders with the header bar automatically.

## Tables

Tables are rounded cards that **hug their content**: the outer border shrinks to the
table and columns are sized to their cells (`auto`), so a short table is a compact
card rather than a full-width band. Both the row and column separators are drawn in `ui-border` (a `top` rule for
every row after the first, a `left` rule for every column after the first), so
every cell is distinguishable without doubling the outer border. `table` (2 columns), `table-3` (3 columns), `table-4`
(4 columns), and `table-5` (5 columns) all expand to this shape (substituting the
column list and cell count):

```typst
#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Header 1*], [*Header 2*]),
    [Row 1 Cell 1], [Row 1 Cell 2],
    [Row 2 Cell 1], [Row 2 Cell 2],
  )
]
```

**Tables keep together.** The theme measures every table and moves the whole table
to the next page when it does not fit, so a table is never left with one or two
orphan rows at the bottom of a page. Always put the header row(s) inside
`table.header(...)` (as above): in the rare case a table is taller than a page and
must break, the header then repeats at the top of the continuation page. The header
is still row 0 for the `fill`/`stroke` functions.

Do **not** add `width: 100%` to the wrapper or use `Nfr` columns: that forces the
card to the full page width while the text stays left-aligned.

`truthtable` uses the same wrapper with `align: center + horizon`, a header fill
of `if row < 2 { ui-surface-raised } else { none }`, `stroke: none`, and a
full-width `table.hline(stroke: 0.5pt + ui-border)` after the `A`/`B` row. Use
`table.hline` here rather than a per-cell stroke function: the row-spanned
`OUTPUT` cell shifts the per-cell `y` indices and truncates the separator.
`truthtable-3` is the three-input variant (`A`, `B`, `C`). Both use `auto` columns
like the other tables. Truth tables are short, so they are covered by the same
keep-together handling and do not need `table.header(...)`.

Keep the wrapper, neutral header fill, and `ui-border` separator exactly as
templated; do not reintroduce `stroke-color` or the accent-tinted header.

## Figures and diagrams

- `figure` → `#figure(image("path", width: 80%), caption: [...])`.
- `figure-labelled` → the same figure with a trailing `<fig:label>` for cross-referencing (`@fig:label`).
- `image` → `#image("path", width: 100%)`.
- `image-grid` → two captioned figures side by side in `#grid(columns: (1fr, 1fr), gutter: 12pt, ...)`.
- `mermaid-erd`, `mermaid-gantt`, `mermaid` → `#mermaid("...")` wrappers for ER, Gantt, and generic diagrams.
  Always pass `theme: mmdr-theme`; the theme makes the diagram background match
  the page and themes nodes, sequence actors/notes, and edges for both themes.
- `circuit` → `#zap.circuit({ import zap: *; cetz.draw.set-style(zap: zap-theme); … })`
  CeTZ/Zap IEEE logic circuit. Always use the theme's `zap-theme` for the
  style — Zap's defaults are black on white, which is illegible on the dark page.
- `cetz` → `#cetz.canvas({ import cetz.draw: *; ... })`.
- `big-o` → the blue "⚡ Big-O" complexity card, using the same left-accent
  structure as a callout (`left: 3pt + rgb("#3182ce")`, `rest: 0.5pt + rgb("#3182ce35")`,
  `fill: rgb("#3182ce15")`, `radius: ui-radius`) plus a bold title and 2-column grid.

Figure captions are styled globally by the theme —
`#show figure.caption: set text(size: 0.85em, style: "italic", fill: rgb("#718096"))`
(smaller, italic, muted grey). Do not re-style captions per figure with your own
`#text(...)`.

Diagrams are the number-one source of failed compiles and are **composed, not
copied**. Before drawing one, read `references/diagrams.md` for the import lines,
the tool-choice table, the Zap/CeTZ/mmdr templates, and the debugging checklist.
The essentials: import the package at the top of the file, and compile after
every diagram you add.

## Headings and layout

- `h1`…`h5` → `= `…`===== ` (these feed the theme's show rules).
- `columns` (2-column), `columns-3` (3-column), `column-break`, `page-break`.
- `align` → `#align(center|left|right)[...]`.
- `grid` → 2-column `#grid` with `gutter: 10pt`.

## Text formatting

`bold` `*bold*`, `italic` `_italic_`, `strikethrough` `#strike[...]`, `highlight` `#highlight[...]`,
`smallcaps` `#smallcaps[...]`, `superscript` `#super[...]`, `subscript` `#sub[...]`.

**Typst emphasis is not Markdown.** `*...*` is strong (bold) and `_..._` is
emphasis (italic) — there is **no** `**` or `__`. Typst has no Markdown mode, so
`**bold**` (or `**not**`, `**C**lass`) parses the doubled stars as an *empty*
strong block and emits a `no text within stars` warning; the text still renders,
but unstyled. **Never emit `**` or `__` in a `.typ` file**, and when editing one
that already contains them, replace each pair with a single delimiter.

Delimiters must sit on a **word boundary**. A `*` immediately followed by a
letter does not close the strong run, so `*C*lass` fails to compile with
`unclosed delimiter`. To bold one or more letters *inside* a word, use the
function form — `#strong[C]lass`, `#strong[R]esponsibilities`,
`#strong[C]ollaborators`. A run may span a line break as long as both delimiters
are on word boundaries, e.g. `*listeners are the Observer\npattern*`.

## Note-taking elements

- `step` / `steps` → numbered `+ *Step N:*` items.
- `key-value` / `term` → bold term + definition.
- `badge` → inline colored pill (`#box(fill: rgb("<hex>20"), inset: (x: 6pt, y: 2pt), radius: ui-radius-sm)[...]`).
- `qa` → `#qa[question][answer]`.
- `uml-class` → `#uml-class("Name", fields: ("- field: Type"), methods: ("+ method(): Type"))`.
- `card` → `#card[body]`.
- `box` → `#box(stroke: 0.5pt + ui-border, inset: (x: 12pt, y: 10pt), radius: ui-radius, width: 100%)[...]`.
- `todo` / `done` → `- [ ]` / `- [x]`.
- `quote` → `#quote(attribution: [...])[...]`.
- `divider` → `#line(length: 100%, stroke: 0.6pt + stroke-color)`.
- `footnote` → `#footnote[...]`.
- `table-of-contents` → `#outline(title: [Contents], depth: 2)`. Outline entries are clickable
  links to their headings (Typst does this automatically).
- `title` → `#note-title(date, title)`.
- `date` → the current date `dd Month YYYY`.

## Links

`link` → `#link("url")[text]`, `url` → `#link("url")`, `link-underline` → `#show link: underline`.

## Mathematics

Inline math is `$...$`; display math is `$ ... $` on its own line. Use **Typst math
names, never LaTeX**, and define each symbol on first use. The full trigger →
expansion tables (delimiters, operators, matrices, relations, sets, Greek letters)
are in `references/math.md`.

## Trigger quick index

Boilerplate: `page`
Callouts: `note` `info` `tip` `warning` `caution` `danger` `important`
`definition` `theorem` `lemma` `corollary` `proposition` `example` `question`
`problem` `solution` `remark` `takeaway` `proof` `callout` `big-o`
Code: `code-show-rule` `raw-show-rule` `code-filename` `code-inline` `line-numbers` `no-line-numbers` `with-line-numbers` `code-block` `code-fence` `code-raw` and `code-python` `code-sql` `code-verilog`
`code-verilog` `code-java` `code-c` `code-cpp` `code-rust` `code-javascript` `code-typescript` `code-shell` `code-bash` `code-nix`
`code-lua` `code-typst` `code-asm` `code-html` `code-css` `code-json` `code-go` `code-haskell` `code-php` `code-xml`
`code-csharp` `code-tcl` `code-gradle`
Notes/lists: `step` `steps` `key-value` `term` `badge` `qa` `uml-class` `card` `box` `todo` `done`
`quote` `date` `divider` `footnote` `table-of-contents` `title`
Tables: `table` `table-3` `table-4` `table-5` `truthtable` `truthtable-3`
Figures/diagrams: `figure` `figure-labelled` `figure-content` `image` `image-grid` `circuit` `cetz` `mermaid-erd` `mermaid-gantt` `mermaid`
`cetz-setup` `mermaid-setup` `big-o`
Layout: `h1` `h2` `h3` `h4` `h5` `columns` `columns-3` `column-break` `page-break` `align` `grid`
Links: `link` `url` `link-underline` `label` `ref` `cite` `bib`
Formatting: `bold` `italic` `strikethrough` `highlight` `smallcaps` `superscript` `subscript`
Math: `$` `$$` `equation` `equation-align` `frac` `sum` `prod` `int` `lim` `sqrt` `root` `abs`
`norm` `pdiff` `diff` `binom` `ceil` `floor` `cases` `vec` `mat` `mat2` `mat3` `det`
`trace` `transpose` `inv` `conj` `hat` `bar` `tilde` `dot` `ddot` `delimiters` `delimiters-bracket` `delimiters-curly`
`set` `set-builder` `infinity` `nabla` `arrow` `arrow-right` `arrow-left` `arrow-up` `arrow-down` `iff` `==>` `therefore`
`because` `forall` `exists` `elem` `notin` `subset` `cup` `cap` `empty` `neq` `leq`
`geq` `approx` `times` `cdot` `real` `natural` `integer` `rational` `complex` `supset` `subset-equal` `superset-equal`
and the Greek triggers `alpha` `beta` `gamma` `delta` `epsilon` `zeta` `eta` `theta` `iota` `kappa` `lambda` `mu`
`nu` `xi` `pi` `sigma` `omega` `phi` `psi` `chi` `rho` `tau` `upsilon` `omicron`

## Maintenance

`references/typst.lua` is copied at build time from
`modules/features/nvim-src/lua/snippets/typst.lua`, which is the single source of
truth. Edit that file (not the copy) when snippets change; the bundled copy
refreshes on the next rebuild.

`references/page-preamble.typ` is the output of the `page` snippet (a few lines
that import the theme). `references/theme.typ` is the full shared theme;
`references/diagrams.md`, `references/math.md`, and `references/example.typ` are
hand-written. The theme and the note header are checked for drift by
`check-sync.sh` at build time — if you change the theme's bindings, the `page`
snippet or `page-preamble.typ`, update all of them together.
