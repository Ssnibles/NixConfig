// Canonical start-of-note header. It imports the shared theme (which lives at
// `/templates/theme.typ` in a notes repository) instead of inlining it. Compile
// with the repository as the Typst root, e.g. `typst compile --root ~/Uni …`.
//
// `templates/theme.typ` itself is bundled alongside this file as
// `references/theme.typ` — copy it into a notes repo that doesn't have it yet.

#import "/templates/theme.typ": *
#show: theme.with(course: "COMPXxxx")

#set document(title: "Lecture X — Title")
#let date = "Week N"

#note-title(date, "Lecture X — Title")

Content here...
