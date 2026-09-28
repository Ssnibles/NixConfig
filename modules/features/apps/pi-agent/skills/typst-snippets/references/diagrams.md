# Diagram reference (CeTZ, Zap, mmdr)

Load this whenever a document needs a figure, circuit, or diagram. `SKILL.md`
covers the trigger names; this file covers how to build and debug them.

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

