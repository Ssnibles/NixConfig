// Worked test-guide example.
//
// This is a *fictional* paper, only to show the shape. In a real guide every
// question, option and mark must come verbatim from the actual paper (see the
// test-notes SKILL.md). Copy the structure, not this content.
//
// Assumes this file lives in a notes repo and is compiled with the repo as the
// Typst root, e.g. `typst compile --root ~/Uni "<guide>.typ"`.

#import "/templates/theme.typ": *
#show: theme.with(course: "COMPX000")

#set document(title: "COMPX000 Test 3 — Study Guide")
#let date = "Test Three revision"

#note-title(date, "Test 3 — Study Guide")

#card[
  *The big picture.* Test Three is 20 marks (10% of the course): *two
  multiple-choice questions* (2 marks) plus *one written testing question*
  (18 marks). The paper tests one idea end to end: choose the right inputs, and
  know how to tell whether the output is correct. Everything below lets you answer
  each question cold.
]

== How Test Three is laid out

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Question*], [*Topic*], [*Marks*]),
    [One], [Two multiple-choice — testing strategy], [2],
    [Two], [Equivalence classes and boundaries], [18],
    [*Total*], [], [*20*],
  )
]

== Question 1 — Multiple choice

=== Answer key

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Q*], [*Answer*], [*Concept tested*]),
    [1], [*b* — Black box testing], [Testing strategy],
    [2], [*b* — FALSE], [Testing can show presence, not absence],
  )
]

=== Q1 — Testing without access to the code

#card[
  *Q1.* Testing which relies on inputs and observing outputs of a system without
  access to the code is what type of testing?

  - *(a)* White box testing
  - *(b)* Black box testing
  - *(c)* Grey box testing
  - *(d)* Glass box testing
]

#callout("✅", "Answer: (b) Black box testing.", "#38a169")[
  *Black-box* testing treats the system as an opaque box: give it inputs, observe
  the outputs, and never look at the implementation.
]

#callout("📝", "Why the others are wrong:", "#3182ce")[
  - *(a) White box* and *(d) Glass box* are the same thing — they *examine the
    code*, the opposite of what the question describes.
  - *(c) Grey box* means partial internal knowledge, whereas the question says
    *no access* to the code.
]

=== Q2 — "Testing proves the program is correct"

#card[
  *Q2.* Testing can prove that a program contains no defects.

  - *(a)* TRUE
  - *(b)* FALSE
]

#callout("✅", "Answer: (b) FALSE.", "#38a169")[
  Dijkstra's rule: *testing can show the presence of bugs, but not their
  absence.* You can never run every possible input, so a passing test suite only
  means no failure was observed.
]

== Question 2 — Equivalence classes and boundaries

#callout("❓", "Question Two:", "#805ad5")[
  A railway system sells to people aged *0 to 120* inclusive. Everything else is
  invalid. Write a Java method `validAge(int age)` that returns `true` only for a
  valid age, then list the equivalence classes and the boundary tests you would
  use. *(18 marks)*
]

#callout("✅", "What the marker is looking for:", "#38a169")[
  - A method that returns `boolean`.
  - The comparison `age >= 0 && age <= 120` (inclusive both ends).
  - *Three* equivalence classes: too small, valid, too large.
  - The boundary values `-1`, `0`, `1`, `119`, `120`, `121` (or at least the
    edges `-1`, `0`, `120`, `121`), each with its expected result.
]

```java
Railway.java
public static boolean validAge(int age) {
    return age >= 0 && age <= 120;
}
```

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Equivalence class*], [*Range*], [*Example tests*]),
    [Invalid — too small], [`-2 147 483 648` to `-1`], [`-1` and `-100` → `false`],
    [Valid], [`0` to `120`], [`0`, `60` and `120` → `true`],
    [Invalid — too large], [`121` to `2 147 483 647`], [`121` and `367` → `false`],
  )
]

#callout("⚠", "Boundary trap:", "#dd6b20")[
  The class ends are *inclusive*, so the comparisons are `>= 0` and `<= 120`. The
  adjacent invalid values `-1` and `121` matter as much as the valid extremes
  `0` and `120` — defects cluster at the edges.
]

== Key takeaways

#callout("📌", "Remember these:", "#dd6b20")[
  - *Black-box* = no access to the code; *white-box* = examine the code.
  - Testing shows the *presence*, never the *absence*, of defects.
  - An *equivalence class* is a set of inputs a reasonable algorithm treats the
    same; test one representative per class.
  - Test the *boundaries* too, including the edge-adjacent invalid values.
]

== Self-test

#qa[What is the difference between black-box and white-box testing?][Black-box provides inputs and observes outputs with no sight of the code; white-box examines the code, documentation and design documents.]

#qa[Why can testing never prove a program correct?][Exhaustively testing every possible input is impossible, so a passing suite only shows that no failure was observed.]

#qa[How many equivalence classes does `validAge` have, and what are they?][Three: invalid-too-small (… to −1), valid (0 to 120), and invalid-too-large (121 to …).]

== Last-minute checklist

- [ ] State the three equivalence classes for a range test.
- [ ] List the four boundary values for an inclusive range.
- [ ] Recite why testing shows presence, not absence.
