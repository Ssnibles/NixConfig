// Golden example — body only.
//
// Assume the file already starts with the shared-theme header from
// references/page-preamble.typ:
//
//   #import "/templates/theme.typ": *
//   #show: theme.with(course: "COMPXxxx")
//
// which brings in the helpers (#callout, #card, #qa, #uml-class, #note-title),
// the `font-sans` / `font-serif` / `font-mono` tokens, and the diagram packages.
// This body then shows a helper callout, math, code, a table, and a diagram
// together. Copy its style, not its content.

== Binary search

_Binary search_ halves the search space each step, so its cost grows
logarithmically. Its running time obeys the recurrence $T(n) = T(n/2) + O(1)$.

#callout("📖", "Definition: Binary search", "#3182ce")[
  An algorithm that repeatedly halves a *sorted* array, comparing the middle
  element to the target, until the target is found or the range is empty.
]

#block(stroke: (left: 3pt + rgb("#3182ce"), rest: 0.5pt + rgb("#3182ce35")), fill: rgb("#3182ce15"), inset: (x: 12pt, y: 10pt), radius: ui-radius, width: 100%)[
  #text(weight: "bold", size: 12pt, fill: rgb("#3182ce"))[⚡ Big-O: Binary search]
  #v(0.4em)
  #grid(
    columns: (1fr, 1fr),
    [*Time Complexity:*], [*Space Complexity:*],
    [- Search: $O(log n)$], [- Aux Space: $O(1)$],
  )
]

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

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border, width: 100%)[
  #table(
    columns: (1fr, 1fr, 1fr),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => if y == 0 { (bottom: 0.5pt + ui-border) } else { none },
    [*Input*], [*Comparisons*], [*Result*],
    [`[1, 3, 5, 7]`, `2`], [2], [found],
    [`[2, 4, 6]`, `5`], [2], [not found],
  )
]

#figure(caption: [Binary search decision flow])[
  #mermaid(
    "graph TD; A[lo, hi] --> B{mid < target?}; B -->|yes| C[lo = mid + 1]; B -->|no| D[hi = mid]; C --> A; D --> A;",
    theme: mmdr-theme,
  )
]

#callout("📌", "Key Takeaway:", "#dd6b20")[
  Halving the input adds only one comparison — logarithmic work, constant
  extra space.
]

#qa[What is the running time of binary search?][$O(log n)$: each step halves the search space, so the number of steps grows with the logarithm of the input.]
