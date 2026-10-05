// Worked revision-sheet example (fictional topic). Copy the shape, not the content.
// Compiles stand-alone in a notes repo: `typst compile --root <repo> <this>`.

#import "/templates/theme.typ": *
#show: theme.with(course: "COMPX000")

#set document(title: "COMPX000 — Revision Sheet")
#let date = "Revision"

#note-title(date, "Revision Sheet")

#card[
  *How to use this.* Cover the answers, then work down the page. Anything you miss,
  mark and re-test first on the next pass.
]

== Design patterns

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  [
    *Singleton* — exactly one instance, global access point (creational, object). \
    *Factory Method* — creation interface, subclass decides (creational, class). \
    *Adapter* — wrap an incompatible interface (structural). \
    *Observer* — notify many dependents on change (behavioural, object).
  ],
  [
    *Purpose axes* — creational / structural / behavioural. \
    *Scope axes* — class (inheritance) / object (composition). \
    *Object adapter* — *has-a* adaptee, delegates. \
    *Class adapter* — *is-a* adaptee (needs multiple inheritance).
  ],
)

#callout("⚠", "Trap:", "#dd6b20")[
  Singleton is *creational*, not structural — and it is *object*-scoped, not class.
]

== Testing vocabulary

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Term*], [*One-line meaning*]),
    [Failure], [observed wrong behaviour],
    [Defect], [flaw in any artefact],
    [Error], [developer's mistake that causes a defect],
    [Oracle], [input/output pair deciding pass or fail],
    [Black box], [no access to the code],
  )
]

== Question bank

#qa[What category and scope is the Singleton?][Creational, object-scoped.]

#qa[Push vs pull in Observer?][Push sends the data with the notification; pull sends a signal and observers fetch it.]

#qa[Why does testing never prove correctness?][It can show the presence, not the absence, of defects.]
