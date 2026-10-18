# Diagram reference (CeTZ, Zap, mmdr)

Load this whenever a document needs a figure, circuit, or diagram. `SKILL.md`
covers the trigger names; this file covers how to build and debug them.

**Every diagram is code-generated — never a screenshot or photo** (unless the
figure is inherently an image, e.g. a software UI or a scan). Three tools:

- **Zap** for digital-logic circuits.
- **CeTZ** for anything where *you* place the shapes: state machines, automata,
  class/object collaboration, block/architecture and data-flow diagrams,
  coordinate sketches, anything with a cycle.
- **mmdr** for what Mermaid genuinely models well: sequence, Gantt, pie, git
  graphs, and *simple acyclic* flowcharts/trees.

## 0. The rule that matters most: render it, then look at it

A diagram is **not** finished when it compiles. mmdr and CeTZ will happily emit
overlapping labels, edges running through boxes, and three arrowheads piled on
one node — none of that is a compile error. You must look at the pixels.

After adding or changing any diagram, render the page to a PNG and `read` it:

```bash
typst compile --root ~/Uni --format png "Note.typ" /tmp/fig-{p}.png
# then read /tmp/fig-<the page with the diagram>.png
```

If you only changed one figure, a throwaway file with the theme header and that
one `#figure(...)` is faster than exporting the whole note. **Iterate until
nothing overlaps, no edge crosses a box it should not, and every arrow is
traceable — then delete the scratch file.** Shipping an unseen diagram is the
single most common way these notes end up looking bad.

## 1. Pick the tool by structure, not by diagram name

mmdr is a **from-scratch layout engine**, not the Mermaid JavaScript renderer.
Its auto-placement is the weak point: it is excellent on simple, mostly-acyclic
graphs and sequences, and it collapses as soon as the graph needs routing.
Learn the failure signatures:

| What you will see | What caused it |
|---|---|
| Two arrowheads stacked on one node, or pointless little self-loops | a **cycle / back-edge** (`C --> A` where `A` already leads to `C`) |
| Edge labels printed on top of each other | **two edges between the same pair** of nodes |
| Tangled near-vertical edges, boxes sitting on labels | **`classDiagram`** associations, or any dense many-to-many graph |
| Transition labels overlapping the state boxes | a state machine with cycles, self-transitions, or several labels per node |
| Long orthogonal edges fanning out of one node | heavy fan-out; readable, but usually better in CeTZ |

If your diagram shows any of those, **do not fight mmdr — build it in CeTZ**,
where you control the coordinates. Choose like this:

| Diagram | Tool |
|---|---|
| Sequence, Gantt, pie, gitGraph | **mmdr** |
| ER | **mmdr** if a plain acyclic entity graph; **CeTZ** if relationships are many/many-to-many |
| Flowchart / tree / chain — **acyclic**, at most one edge per pair | **mmdr** |
| Any graph with a **cycle or back-edge** (state machine, automaton, feedback loop) | **CeTZ** |
| **Class / object collaboration** diagram | **CeTZ**, or a `#grid` of `#uml-class` boxes with the associations in prose/table |
| Block / architecture / data-flow diagram, coordinate sketch | **CeTZ** |
| Logic gates / digital circuits | **Zap** |

Rule of thumb: **if you would need a legend to explain the edge routing, use
CeTZ.**

### Imports and versions

With `#import "/templates/theme.typ": *`, `cetz`, `zap`, `mermaid`, `mmdr-theme`
and `zap-theme` are all in scope — **no extra imports needed**. If you are *not*
using the theme, import them yourself (the `cetz-setup` / `mermaid-setup`
snippets emit these lines):

```typst
#import "@preview/cetz:0.5.2"
#import "@preview/zap:0.6.0"   // only needed for digital-logic circuits
#import "@preview/mmdr:0.2.2": mermaid
```

These are the versions installed on this machine. Keep them pinned and do **not**
paste examples written for other versions — the CeTZ API changed across 0.3, 0.4
and 0.5 (for example `..bezier` spreads and some old helpers no longer exist).
If a function is "unknown" or an argument "cannot be spread", the example you
copied is for the wrong version.

### Theme the diagram from the theme

Never hardcode `black`/`white`. Mermaid gets `theme: mmdr-theme`; Zap gets
`zap-theme`; CeTZ strokes with `text-colour` and fills with `bg-colour`. A
hardcoded colour is invisible in one of the two themes (e.g. Zap's default
black-on-white gates vanish on the dark page). Label backgrounds must be
`bg-colour` so an opaque label can sit on top of an edge without a box showing
through.

**Compile after every diagram you add.** A broken canvas can take down the whole
document; catching it immediately tells you exactly which block is at fault.

## 2. mmdr: Mermaid diagrams (write defensively)

Always pass `theme: mmdr-theme`, and put a comma after the closing quote of the
diagram string, before any named argument:

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

Supported: `graph`/`flowchart` (LR/TD), `sequenceDiagram`, `stateDiagram-v2`,
`classDiagram`, `erDiagram`, `mermaid-gantt`, `pie`, `gitGraph`. Keep node
labels short and wrap the diagram in a `#figure`. Because the layout is fragile,
author to its limits:

- **Never create a cycle** in `graph`/`flowchart`. Even `A --> B; B --> A`
  produces stacked arrowheads and fake self-loops. Redraw as a linear list of
  steps, or move the figure to CeTZ.
- **One edge per pair of nodes.** If two things flow between the same two nodes,
  merge the label (`"notify / return"`) or draw two clearly separated arrows in
  CeTZ. Two labelled parallel edges always collide.
- **One label per edge, and keep it to one or two words.** Put it on a single
  direction only.
- **Keep node text to one short line.** Long labels stretch columns and shove
  neighbours into each other.
- **Prefer `graph LR`** for pipelines and `TD` for step sequences; deep `TD`
  chains get very tall.
- **Avoid `classDiagram`** beyond a two-box stub — associations overlap. Use
  CeTZ or `#uml-class` instead.
- **`sequenceDiagram` is the most reliable type.** Use it for interactions.

Safe (acyclic, one label per edge):

```typst
#figure(caption: [Data binding pipeline])[
  #mermaid("graph LR; A[Data source] --> B[Adapter] --> C[AdapterView];",
    theme: mmdr-theme)
]
```

Unsafe — this is the pattern that produced the broken state and observer
figures. Two edges share the `Subject`/`Observer` pair, so the labels land on
top of each other:

```typst
// DON'T: parallel labelled edges
"graph LR; S[Subject] -->|notify| O[Observer]; O -->|requests| S"
```

If you must keep it in Mermaid, collapse to a single directed edge and explain
the return path in the caption. Otherwise use the collaboration recipe in §3.

## 3. CeTZ: the general canvas

`cetz.draw` functions are available after `import cetz.draw: *` inside the
canvas. Coordinates are centimetres. Set the style once, before drawing, so the
first shape is not left unthemed.

```typst
#cetz.canvas({
  import cetz.draw: *
  set-style(stroke: (paint: text-colour, thickness: 0.9pt), fill: none)
  rect((0, 0), (1.2, 1))                    // two opposite corners
  circle((3, 0.5), radius: 0.5)
  line((1.2, 0.5), (2.5, 0.5), mark: (end: ">", fill: text-colour))
  content((0.6, 0.5), [Block])              // labels are Typst content (math works)
  content((3, 0.5), [$q_0$])
})
```

Key primitives:

- `line(..points, mark: (end: ">", fill: text-colour))` — straight segment, or a
  poly-line when given intermediate points (use this for orthogonal back-edges).
- `bezier(from, to, control, mark: (end: ">", fill: text-colour))` — a curved
  edge; the third point pulls the curve.
- `rect(a, b, radius: 0.12, name: "x")`, `circle(pos, radius: ..)`,
  `content(pos, [label])`.
- Name a shape (`name: "start"`) and anchor to it: `"start.north"`, `.south`,
  `.east`, `.west`, and the corners `"start.north-east"`. This is what keeps
  arrows attached to boxes when you move them.

### Reusable helpers (paste into every canvas)

These two helpers remove almost all the fiddly work. `node` draws a centred
rounded box with a name; `tag` draws an opaque label that can sit over an edge.
Both are used by every recipe below.

```typst
let node(name, x, y, label, w: 3.2, h: 0.8) = {
  rect((x - w/2, y - h/2), (x + w/2, y + h/2), radius: 0.12, name: name)
  content((x, y), text(size: 9pt, fill: text-colour)[#label])
}
let tag(x, y, label) = content(
  (x, y), fill: bg-colour, frame: "rect", stroke: none, padding: 2.5pt,
  text(size: 8pt, fill: text-colour)[#label],
)
```

Use `\` inside a node label for a second line (`[Data source \ array / cursor]`).
Give boxes a little more `w` than the longest label needs — overflow is invisible
until you look at the render.

### State machine (cycles, self-loops, back-edges)

A lifecycle / state diagram is **CeTZ, never mmdr**. Lay the states in a single
column, put straight arrows down the middle, and route feedback edges around the
outside. This is the exact figure mmdr could not draw: `onPause` ⇄ `onResume`
(self-loop) and the `onRestart → onStart` back-edge.

```typst
#figure(caption: [Activity lifecycle])[
  #cetz.canvas({
    import cetz.draw: *
    set-style(stroke: (paint: text-colour, thickness: 0.9pt), fill: none)
    let node(name, x, y, label, w: 3.2, h: 0.8) = {
      rect((x - w/2, y - h/2), (x + w/2, y + h/2), radius: 0.12, name: name)
      content((x, y), text(size: 9pt, fill: text-colour)[#label])
    }
    let tag(x, y, label) = content((x, y), fill: bg-colour, frame: "rect",
      stroke: none, padding: 2.5pt, text(size: 8pt, fill: text-colour)[#label])

    node("create",  0,    0.0, [onCreate])
    node("start",   0,   -1.6, [onStart])
    node("resume",  0,   -3.2, [onResume])
    node("pause",   0,   -4.8, [onPause])
    node("stop",    0,   -6.4, [onStop])
    node("destroy", -2.5, -8.3, [onDestroy])
    node("restart",  2.5, -8.3, [onRestart])

    circle((0, 1.0), radius: 0.15, fill: text-colour, stroke: none)      // start marker
    line((0, 0.85), "create.north", mark: (end: ">", fill: text-colour))
    line("create.south", "start.north", mark: (end: ">", fill: text-colour))
    line("start.south",  "resume.north", mark: (end: ">", fill: text-colour))

    // transition + label
    line("resume.south", "pause.north", mark: (end: ">", fill: text-colour))
    tag(0, -4.0, [loses focus])

    // self-loop: out the east of both boxes, curved to the right, labelled
    bezier("pause.east", "resume.east", (2.0, -4.0), mark: (end: ">", fill: text-colour))
    tag(2.0, -3.75, [regains focus])

    line("pause.south", "stop.north", mark: (end: ">", fill: text-colour))
    tag(0, -5.6, [no longer visible])
    line("stop.south", "destroy.north", mark: (end: ">", fill: text-colour))
    tag(-1.25, -7.35, [finishing])
    line("stop.south", "restart.north", mark: (end: ">", fill: text-colour))
    tag(1.25, -7.35, [returning])

    // back-edge: right of everything, then up and into onStart.east
    line("restart.east", (4.6, -8.3), (4.6, -1.6), "start.east",
      mark: (end: ">", fill: text-colour))
  })
]
```

Keep every feedback edge **outside** the column (x beyond the widest box) so it
never crosses a state. If two back-edges run on the same side, give them
different x offsets.

### Block / architecture / data-flow diagram

Horizontal flow, boxes evenly spaced, labels above the arrows. Fan-out to
repeated items (here three `Row view`s) is fine — just space the targets
vertically so the arrows do not bundle.

```typst
#figure(caption: [Adapter pipeline])[
  #cetz.canvas({
    import cetz.draw: *
    set-style(stroke: (paint: text-colour, thickness: 0.9pt), fill: none)
    let node(name, x, y, label, w: 2.4, h: 0.9) = {
      rect((x - w/2, y - h/2), (x + w/2, y + h/2), radius: 0.1, name: name)
      content((x, y), text(size: 8.5pt, fill: text-colour)[#label])
    }
    let tag(x, y, label) = content((x, y), fill: bg-colour, frame: "rect",
      stroke: none, padding: 2.5pt, text(size: 8pt, fill: text-colour)[#label])

    node("src",     0,    0,    [Data source \ array / cursor], w: 3.2, h: 1.0)
    node("adapter", 4.6,  0,    [Adapter], w: 2.2)
    node("view",    8.9,  0,    [AdapterView \ / ListView], w: 3.0, h: 1.0)
    node("r1",     13.4,  1.5,  [Row view], w: 2.2, h: 0.7)
    node("r2",     13.4,  0.0,  [Row view], w: 2.2, h: 0.7)
    node("r3",     13.4, -1.5,  [Row view], w: 2.2, h: 0.7)

    line("src.east", "adapter.west", mark: (end: ">", fill: text-colour))
    line("adapter.east", "view.west", mark: (end: ">", fill: text-colour))
    tag(6.75, 0.55, [binds each item])
    line("view.east", "r1.west", mark: (end: ">", fill: text-colour))
    line("view.east", "r2.west", mark: (end: ">", fill: text-colour))
    line("view.east", "r3.west", mark: (end: ">", fill: text-colour))
  })
]
```

### Class / object collaboration diagram

One subject fanning out to several collaborators, plus **one** labelled reverse
edge — the Observer pattern. Route the reverse edge on the far side (right, over
the top, or under the bottom) and give it a single label; do not draw an
unlabelled parallel pair.

```typst
#figure(caption: [Observer pattern])[
  #cetz.canvas({
    import cetz.draw: *
    set-style(stroke: (paint: text-colour, thickness: 0.9pt), fill: none)
    let node(name, x, y, label, w: 2.4, h: 0.9) = {
      rect((x - w/2, y - h/2), (x + w/2, y + h/2), radius: 0.1, name: name)
      content((x, y), text(size: 9pt, fill: text-colour)[#label])
    }
    let tag(x, y, label) = content((x, y), fill: bg-colour, frame: "rect",
      stroke: none, padding: 2.5pt, text(size: 8pt, fill: text-colour)[#label])

    node("subject", 0,    0,    [Subject])
    node("o1",      5.4,  1.7,  [Observer])
    node("o2",      5.4,  0,    [Observer])
    node("o3",      5.4, -1.7,  [Observer])

    line("subject.east", "o1.west", mark: (end: ">", fill: text-colour))
    line("subject.east", "o2.west", mark: (end: ">", fill: text-colour))
    line("subject.east", "o3.west", mark: (end: ">", fill: text-colour))
    tag(3.1, 0.35, [notify()])

    // single reverse edge, routed above the fan on the far right
    line("o2.east", (7.6, 0), (7.6, 3.0), (0, 3.0), "subject.north",
      mark: (end: ">", fill: text-colour))
    tag(3.8, 3.25, [attach / detach])
  })
]
```

For a fuller UML treatment, put `#uml-class("Subject", …)` boxes in a `#grid`
and state the associations in the caption or a small table; exact UML arrowheads
are not worth fighting CeTZ for.

### Automaton / small graph

```typst
#cetz.canvas({
  import cetz.draw: *
  set-style(stroke: (paint: text-colour, thickness: 0.8pt), fill: none)
  circle((0, 0), radius: 0.35)
  content((0, 0), [$q_0$])
  circle((1.5, 0), radius: 0.35)
  content((1.5, 0), [$q_1$])
  line((0.35, 0), (1.15, 0), mark: (end: ">", fill: text-colour))
  content((0.75, 0.2), [a])
  bezier((1.5, 0.35), (0, 0.35), (0.75, 0.95), mark: (end: ">", fill: text-colour))
  content((0.75, 0.55), [b])
})
```

## 4. Zap: digital logic circuits

Importing `zap: *` also brings `cetz` into scope, which is why the style call is
`cetz.draw.set-style(...)`.

```typst
#zap.circuit({
  import zap: *
  cetz.draw.set-style(zap: zap-theme)  // themed: gate/label colour follows text-colour
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

`node(name, pos, label: ...)` creates a labelled endpoint; `wire(from, to,
anchor: "east"/"west")` draws the connection. Use `import zap: *` for the gate,
node and wire functions, and `cetz.draw.*` for anything else.

## 5. Debugging and QA checklist

Run this before calling a diagram done.

- [ ] **You have looked at the rendered PNG.** (Render the page and `#read` it.)
- [ ] No two labels overlap, and no label sits on a box or line.
- [ ] No edge passes through a box it is not connected to.
- [ ] No node has stacked/multiple arrowheads or a stray self-loop.
- [ ] Every feedback/back edge runs outside the main row/column of boxes.
- [ ] Node text fits inside its box (widen `w`, or add a `\` line break).
- [ ] The diagram is not wider/taller than the page margin; wrap it in
      `#figure(caption: [...])[...]`, and for side-by-side use
      `#grid(columns: (1fr, 1fr), align: center + horizon, …)`.

Common fixes:

- Missing `#import` → `unknown variable: cetz` / `zap` / `mermaid`. Add the
  import at the top (rule 1).
- Mermaid renders a white box on the dark page → you forgot `theme: mmdr-theme`.
- "expected comma" on a Mermaid string → add a `,` after the closing quote
  before `theme:`.
- CeTZ shapes use default styling → `set-style(...)` must come *before* drawing.
- Overlapping/overflowing shapes → spread the coordinates out, or switch from
  mmdr to CeTZ.
- If a diagram is proving hard to draw correctly, simplify it (fewer nodes, less
  text) or describe it in prose rather than shipping a broken canvas.
