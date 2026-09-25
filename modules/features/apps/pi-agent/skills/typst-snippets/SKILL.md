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

## Always start from the page preamble

Most snippets assume the document preamble defined by the `page` snippet. It sets
the variables `theme` (`"dark"`/`"light"`), `page-type` (`"notes"`/`"lecture"`),
`course`, `date`, `bg-color`, `text-color`, and `stroke-color`, and installs the
`#show` rules for headings, links, block/inline `raw`, and the title block.

It also defines the shared UI design tokens that every block now uses, so all
containers stay visually consistent:

- `ui-radius = 6pt` — corner radius for every block (callouts, cards, code blocks,
  tables). `ui-radius-sm = 3pt` for inline pills and inline code.
- `ui-border` — subtle border color (`#2e2f38` dark / `#e2e2e8` light), used instead
  of the bright `stroke-color` for container borders.
- `ui-surface` — raised panel fill for cards and code blocks.
- `ui-surface-raised` — header/row fill for code headers and table headers.

**Every block rounds all four corners** (no more one-sided radii) and uses the
`ui-*` tokens rather than ad-hoc colors. Callouts keep their colored left accent
bar, but now share the same 6pt radius, 0.5pt base border, and 12pt/10pt inset as
the other containers.

**If a Typst document does not already contain this preamble, insert it first** by
reproducing the `page` snippet expansion from `references/typst.lua` exactly.
Callouts, cards, boxes, tables, code blocks, `cbf`, and `bigo` reference the
`theme`/`ui-*` variables, so they render incorrectly (or fail) without it.

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

Every callout (`note`, `info`, `tip`, `warn`/`warning`, `caution`, `danger`,
`important`, `def`/`definition`, `thm`/`theorem`, `lem`/`lemma`, `cor`/`corollary`,
`prop`, `ex`/`example`, `question`, `prob`, `sol`, `rem`/`remark`, `key`/`takeaway`)
expands to exactly:

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

Substitute the accent color and the icon/title/label per the trigger. Icon + title
pairs: 📝 Note, ℹ Info, 💡 Tip, ⚠ Warning, 🚨 Caution, 🛑 Danger, ❗ Important,
📖 Definition, 📐 Theorem, 🧩 Lemma, 📎 Corollary, 💡 Proposition, ✏ Example,
❓ Question, ❓ Problem, 💡 Solution, 💬 Remark, 📌 Key Takeaway.

The generic `callout` snippet is the same pattern with a color `choice_node`
(blue → green → orange → red → purple).

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

- `codeshow` / `rawshow` insert the `lang-meta` map plus the `#show raw.where(block: true)`
  rule (background, radius, stroke, header bar with Nerd Font devicon + filename/lang)
  and the `#show raw.where(block: false)` inline-code rule. Drop the full block in
  verbatim; do not simplify it.
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

If a document uses code blocks, make sure `codeshow`/`rawshow` has been applied so
they render with the header bar; otherwise the fenced block falls back to plain raw.

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

## Figures, media, and diagrams

- `fig` → `#figure(image("path", width: 80%), caption: [...])`.
- `img` → `#image("path", width: 100%)`.
- `gridimg` → two captioned figures side by side in `#grid(columns: (1fr, 1fr), gutter: 12pt, ...)`.
- `erd`, `gantt`, `mmd` → `#mermaid("...")` wrappers for ER, Gantt, and generic diagrams.
- `circuit` → `#zap.circuit({ import zap: *; ... })` CeTZ/Zap IEEE logic circuit.
- `cetz` → `#cetz.canvas({ import cetz.draw: *; ... })`.
- `bigo` → the blue "⚡ Big-O" complexity card, using the same left-accent
  structure as a callout (`left: 3pt + rgb("#3182ce")`, `rest: 0.5pt + rgb("#3182ce35")`,
  `fill: rgb("#3182ce15")`, `radius: ui-radius`) plus a bold title and 2-column grid.

## Diagrams (CeTZ, Zap, and mmdr)

**Every diagram is code-generated — never a screenshot or photo** (unless the
figure is inherently an image, e.g. a software UI or a scan). Use one of three
tools:

- **Zap** for digital-logic circuits.
- **CeTZ** for anything geometric: automata, graphs, trees, block/architecture
  diagrams, coordinate sketches.
- **mmdr** for anything Mermaid models well: flowcharts, sequence, state, class,
  ER, Gantt, pie, git graphs. Prefer mmdr when it fits — it is far less
  error-prone than placing CeTZ coordinates by hand.

Diagrams are the number-one source of failed compiles. The two rules that fix
almost all of them:

1. **Import the package(s) at the very top of the file.** The `page` preamble does
   *not* import them, and `#cetz`/`#zap`/`mermaid` are unknown without this (the
   `cetzsetup` and `mmdsetup` snippets emit these lines):

   ```typst
   #import "@preview/cetz:0.5.2"
   #import "@preview/zap:0.6.0"   // only needed for digital-logic circuits
   #import "@preview/mmdr:0.2.2": mermaid
   ```

   These are the versions installed on this machine. Keep them pinned and do not
   paste examples written for other versions — the CeTZ API changed across 0.3,
   0.4, and 0.5 (for example, `..bezier` spreads and some old helpers no longer
   exist). If a function is "unknown" or an argument "cannot be spread", the
   example you copied is for the wrong version.

2. **Compile after every diagram you add.** A broken canvas can take down the
   whole document; catching it immediately tells you exactly which block is at
   fault.

Pick the right tool:

| Diagram | Use |
|---|---|
| Logic gates / digital circuits | Zap `#zap.circuit(...)` |
| Automata, graphs, trees, block/architecture diagrams, coordinate sketches | CeTZ `#cetz.canvas(...)` |
| Flowcharts, sequence, ER, Gantt, class diagrams | Mermaid (`mmd`, `erd`, `gantt`) |

Unlike the text snippets, diagrams are **composed, not copied** — use the
templates below as starting points and build the specific figure you need.

### Zap: digital logic circuits

Importing `zap: *` also brings `cetz` into scope, which is why the style call is
`cetz.draw.set-style(...)`.

```typst
#zap.circuit({
  import zap: *
  cetz.draw.set-style(zap: (variant: "ieee"))
  node("A", (0, 0.2), label: (content: "A", anchor: "west", distance: 2pt))
  node("B", (0, -0.2), label: (content: "B", anchor: "west", distance: 2pt))
  node("C", (2.5, 0), label: (content: "C", anchor: "east", distance: 2pt))
  land("g1", (1.25, 0), label: "AND")
  wire("A", "g1.in1", anchor: "east")
  wire("B", "g1.in2", anchor: "east")
  wire("g1.out", "C", anchor: "west")
})
```

Gate functions (all take `(name, position, label: ...)` and expose `.in1`,
`.in2`, `.out` anchors):

| Function | Gate | Function | Gate |
|---|---|---|---|
| `land` | AND | `lnand` | NAND |
| `lor` | OR | `lnor` | NOR |
| `lxor` | XOR | `lxnor` | XNOR |
| `lnot` | NOT (use `.in1` → `.out`) | | |

`node(name, pos, label: ...)` creates a labeled endpoint; `wire(from, to,
anchor: "east"/"west")` draws the connection. Use `import zap: *` for the gate,
node, and wire functions, and `cetz.draw.*` for anything else (arrows, text,
groups).

### CeTZ: general diagrams

The `cetz.draw` functions are available after `import cetz.draw: *` inside the
canvas. Coordinates are in centimetres. Use the theme's `text-color` for strokes
so diagrams match the page.

```typst
#cetz.canvas({
  import cetz.draw: *
  set-style(stroke: (paint: text-color, thickness: 0.8pt), fill: none)
  // shapes
  rect((0, 0), (1.2, 1))
  circle((3, 0.5), radius: 0.5)
  // arrow
  line((1.2, 0.5), (2.5, 0.5), mark: (end: ">"))
  // labels (Typst content, so math works)
  content((0.6, 0.5), [Block])
  content((3, 0.5), [$q_0$])
})
```

Useful primitives: `line`, `rect`, `circle`, `bezier(start, end, control,
mark: (end: ">"))`, `content(pos, [label])`, `grid`, `arc`, `polygon`. Give an
element `name: "x"` and connect it later with `line("x.east", "y.west")`.

Automaton / state machine:

```typst
#cetz.canvas({
  import cetz.draw: *
  set-style(stroke: (paint: text-color, thickness: 0.8pt), fill: none)
  circle((0, 0), radius: 0.35)
  content((0, 0), [$q_0$])
  circle((1.5, 0), radius: 0.35)
  content((1.5, 0), [$q_1$])
  line((0.35, 0), (1.15, 0), mark: (end: ">"))
  content((0.75, 0.2), [a])
  // curved return edge: bezier(start, end, control-point)
  bezier((1.5, 0.35), (0, 0.35), (0.75, 0.95), mark: (end: ">"))
  content((0.75, 0.55), [b])
})
```

### mmdr: Mermaid diagrams

Always pass `theme: mmdr-theme` (defined in the `page` preamble) so the diagram
matches the dark page instead of rendering a white box. The diagram source is a
multiline string and must be followed by a comma before any named argument.

```typst
#mermaid(
  "graph LR; A[Start]-->B{Decision}; B-->|yes|C[Do]; B-->|no|D[Stop];",
  theme: mmdr-theme,
)
```

Supported diagram types: `graph`/`flowchart` (LR/TD), `sequenceDiagram`,
`stateDiagram-v2`, `classDiagram`, `erDiagram`, `gantt`, `pie`, `gitGraph`. The
renderer does **not** implement all of Mermaid JS — if a diagram errors, simplify
the syntax or fall back to CeTZ. Keep node labels short, and wrap it in a figure:

```typst
#figure(caption: [Light controller state machine])[
  #mermaid(
    "stateDiagram-v2
      [*] --> Off
      Off --> On: press
      On --> Off: press",
    theme: mmdr-theme,
  )
]
```

### Diagram debugging checklist

- Missing `#import` → `unknown variable: cetz` / `unknown variable: zap` /
  `unknown variable: mermaid`. Add the import at the top (rule 1).
- Mermaid renders a white box on the dark page → you forgot
  `theme: mmdr-theme`.
- "expected comma" on a Mermaid string → add a `,` after the closing quote
  before `theme:`.
- Keep every drawing call inside `#zap.circuit({ ... })` or
  `#cetz.canvas({ ... })`, with `import cetz.draw: *` as the first line inside a
  `cetz.canvas` block.
- `set-style(...)` before drawing, not after, or the first shapes use defaults.
- Overlapping/overflowing shapes usually mean the coordinates are too close or
  the diagram is too wide. Spread coordinates out and wrap the canvas in
  `#figure(caption: [...])[...]`; for side-by-side layouts use
  `#grid(columns: (1fr, 1fr), align: center + horizon, ...)`.
- If a diagram is proving hard to generate correctly, fall back to Mermaid or a
  short prose description rather than shipping a broken canvas.

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

Inline `$...$`, display `$ ... $`; multi-line `eq`, aligned `eqalign` (`&=`).
Symbols map to Typst math names (not LaTeX): `frac (a)/(b)`, `sum_(i=0)^(n)`,
`prod_...`, `integral_(a)^(b)` (trigger `int`), `lim_(x -> inf)`, `sqrt`, `root(n, x)`,
`abs |x|`, `norm ||x||`, `(diff f)/(diff x)` (`pdiff`), `(d f)/(d x)` (`diff`),
`binom`, `ceil`, `floor`, `cases`, `vec`, `mat`/`mat2`/`mat3`, `det`, `tr` (`trace`),
`^T` (`transpose`), `^(-1)` (`inv`), `conj`, `hat`, `overline` (`bar`), `tilde`,
`dot`, `dot.double` (`ddot`), `lr(...)`, `lr([...])`, `lr({...})`, set literals,
`infinity`, `nabla`, `arrow`/`arrow.r`/`arrow.l`/`arrow.t`/`arrow.b`,
`<==>` (`iff`), `==>`, `therefore`, `because`, `forall`, `exists`, `in`, `in.not`,
`subset`, `union`, `intersection`, `nothing`, `!=`, `<=`, `>=`, `approx`, `times`,
`dot.c`, `RR`, `NN`, `ZZ`, `QQ`, `CC`, and Greek names (`alpha`, `beta`, `gamma`,
`delta`, `epsilon`, `theta`, `lambda`, `mu`, `pi`, `sigma`, `omega`, `phi`, `psi`,
`rho`, `tau`).

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
truth. Edit that file (not the copy) when snippets change; the bundled copy refreshes
on the next rebuild.
