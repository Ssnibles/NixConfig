// Golden example — body only.
//
// Assume the file already starts with the shared-theme header from
// references/page-preamble.typ:
//
//   #import "/templates/theme.typ": *
//   #show: theme.with(course: "COMPXxxx")
//
// which brings in the helpers (#callout, #card, #qa, #uml-class, #bigo,
// #keep-together, #note-title), the `font-sans` / `font-serif` / `font-mono`
// tokens, and the diagram packages.
// This body then shows a helper callout, math, code, a table, and a diagram
// together. Copy its style, not its content.

== Binary search

_Binary search_ halves the search space each step, so its cost grows
logarithmically. Its running time obeys the recurrence $T(n) = T(n/2) + O(1)$.

#callout("📖", "Definition: Binary search", "#3182ce")[
  An algorithm that repeatedly halves a *sorted* array, comparing the middle
  element to the target, until the target is found or the range is empty.
]

#bigo("Binary search", grid(
  columns: (1fr, 1fr),
  [*Time Complexity:*], [*Space Complexity:*],
  [- Search: $O(log n)$], [- Aux Space: $O(1)$],
))

Expanding the recurrence gives the familiar bound:

$ T(n) = T(n/2) + O(1) ==> T(n) = O(log n) $

```python
search.py
def binary_search(items, target):
    lo, hi = 0, len(items)
    while lo < hi:
        mid = (lo + hi) // 2
        if items[mid] < target:
            lo = mid + 1
        else:
            hi = mid
    return lo
```

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Input*], [*Comparisons*], [*Result*]),
    [`[1, 3, 5, 7]`, `2`], [2], [found],
    [`[2, 4, 6]`, `5`], [2], [not found],
  )
]

// The loop is a cycle, so this is CeTZ, not mmdr (see references/diagrams.md).
#figure(caption: [Binary search loop])[
  #cetz.canvas({
    import cetz.draw: *
    set-style(stroke: (paint: text-colour, thickness: 0.9pt), fill: none)
    let node(name, x, y, label, w: 3.6, h: 0.8) = {
      rect((x - w/2, y - h/2), (x + w/2, y + h/2), radius: 0.12, name: name)
      content((x, y), text(size: 9pt, fill: text-colour)[#label])
    }
    let tag(x, y, label) = content((x, y), fill: bg-colour, frame: "rect",
      stroke: none, padding: 2.5pt, text(size: 8pt, fill: text-colour)[#label])

    node("mid", 0, 0, [$"mid" = ("lo" + "hi") slash 2$])
    node("cmp", 0, -1.8, [$A_"mid" = "target"$])
    node("yes", -2.8, -3.8, [return $"mid"$])
    node("no", 2.8, -3.8, [shrink $["lo", "hi"]$])

    line((0, 1.0), "mid.north", mark: (end: ">", fill: text-colour))
    line("mid.south", "cmp.north", mark: (end: ">", fill: text-colour))
    line("cmp.south-west", "yes.north-east", mark: (end: ">", fill: text-colour))
    tag(-1.6, -3.1, [yes])
    line("cmp.south-east", "no.north-west", mark: (end: ">", fill: text-colour))
    tag(1.6, -3.1, [no])
    // loop edge: right of everything, back up into mid
    line("no.east", (5.0, -3.8), (5.0, 0), "mid.east", mark: (end: ">", fill: text-colour))
  })
]

#callout("📌", "Key Takeaway:", "#dd6b20")[
  Halving the input adds only one comparison — logarithmic work, constant
  extra space.
]

#qa[What is the running time of binary search?][$O(log n)$: each step halves the search space, so the number of steps grows with the logarithm of the input.]
