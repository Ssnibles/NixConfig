// Worked lecture-notes body (fictional topic). Copy the shape, not the content.
// Compiles stand-alone in a notes repo: `typst compile --root <repo> <this>`.

#import "/templates/theme.typ": *
#show: theme.with(course: "COMPX000")

#set document(title: "Lecture 7 — Binary search")
#let date = "Week 4"

#note-title(date, "Lecture 7 — Binary search")

#card[
  *The big picture.* Searching a *sorted* array can be much faster than scanning
  it, because each comparison eliminates half of the remaining candidates. The
  whole lecture is one idea — halve the range — plus its conditions and its costs.
]

== What you should be able to answer

- Why does binary search require a sorted array?
- How many comparisons does it take in the worst case?
- What is the most common off-by-one bug?

== Definition

#callout("📖", "Definition — binary search:", "#3182ce")[
  An algorithm that repeatedly halves a *sorted* range, comparing the middle
  element to the target, until the target is found or the range is empty.
]

The mechanism is the halving. If the middle element is too small, the target can
only be to its right, so the left half is discarded; if it is too large, the right
half is discarded. The range shrinks by a factor of two each step.

#callout("💡", "Worked example:", "#38a169")[
  Searching `[2, 4, 7, 9, 12, 15]` for `12`: compare with `9` (too small) → keep
  the right half; compare with the middle of `[12, 15]` → found in two comparisons,
  versus four for a linear scan.
]

#callout("⚠", "Common mistake:", "#dd6b20")[
  Using `<=` in the loop condition but not shrinking the range, or forgetting that
  the input must be *sorted*. Both produce wrong answers that look almost right.
]

== Cost

Each step halves the range, so after $k$ steps at most $n\/2^k$ candidates remain.
The search ends when $n\/2^k <= 1$, giving $k <= log_2 n$ comparisons.

#bigo("Binary search", grid(
  columns: (1fr, 1fr),
  [*Time:*], [*Space:*],
  [$O(log n)$], [$O(1)$],
))

== Self-test

#qa[Why must the array be sorted?][The halving argument relies on all elements left of the middle being smaller and all to the right being larger; unsorted data breaks that invariant.]

#qa[How many comparisons for $n = 1024$ in the worst case?][$log_2 1024 = 10$.]

== Key takeaways

#callout("📌", "Remember:", "#dd6b20")[
  - Sorted input is a *precondition*, not an optimisation.
  - Halving gives $O(log n)$ comparisons.
  - The classic bug is the boundary condition, not the comparison.
]
