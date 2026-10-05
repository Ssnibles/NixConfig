---
name: lab-notes
description: Turn lab sessions, practicals, exercises, or lab handouts into clear lab notes. Use whenever the user is recording a lab, writing up a practical or programming/system/electronics exercise, or turning lab instructions, results or screenshots into Typst notes. The result must explain what was done and why it worked — never just paste the worksheet or list numbers.
---

# Lab / practical → lab notes

A lab note is a **record of an experiment plus the reasoning behind it**. The
reader has the handout; what they need is a clean statement of the aim, the method
actually used, the results, and an explanation of *why* those results are what they
are.

**The one-line test:** if the note only reproduces the worksheet, or lists numbers
with no explanation, it is not finished.

Styling comes from the `typst-snippets` skill (load it). For the study-note mindset
(explain, connect, self-test) see `lecture-notes`; for a graded write-up see
`assignment-report`.

## 1. Read the handout and capture the evidence

- Extract the lab sheet: `pdftotext lab.pdf -` (poppler may live under
  `/nix/store/*-poppler-utils-*/bin/`), then render pages to images
  (`pdftoppm -png -r 150 lab.pdf lab`) for diagrams and expected outputs.
- As you work, capture **one figure per result** (waveform, query output, terminal
  run, running app). Crop to what matters, keep files under ~500 KB, and give them
  descriptive names.
- Note what went wrong while it is fresh. A "problems and fixes" note is often the
  most useful part of a lab record.

## 2. Structure

1. **Header** — theme preamble + `#note-title(date, title)` for a theme-based note
   (see Styling).
2. **Big picture** (`#card`) — the aim in one or two sentences, and the single
   concept the lab demonstrates.
3. **Aim / objective** — what the lab is meant to show or build.
4. **Method / setup** — numbered steps (`+ *Step N:*`) of what was actually done:
   the circuit, schema, inputs, tools, versions. Enough to reproduce it.
5. **Observations and results** — the raw evidence:
   - one `#figure(image(...), caption: [...])` per result, referenced by `@fig:…`;
   - measured data in a content-hugging table;
   - label units and axes; state the expected value if there is one.
6. **Analysis** — *why* the result happened. Tie each observation back to the
   theory (name the lecture or concept) and show any calculation.
7. **Answers to the lab questions** — if the handout asks questions, answer each
   one explicitly (`#qa` is ideal).
8. **Problems and fixes** — what went wrong and how it was resolved.
9. **Key takeaways** (`#callout("📌", …)`) and a short **self-test** (`#qa`).

## 3. Figures and data

```typst
#figure(
  image("figures/query-result.png", width: 80%),
  caption: [Rows returned by the join in @fig:query.],
) <fig:query>
```

- **Crop, don't shrink.** The important numbers must stay legible.
- **Reference every figure** in the text; an unmentioned figure is clutter.
- Prefer a **fenced code block** over a screenshot when the result is text (a SQL
  query, a trace, program output).
- Put measured values in a table rather than only in prose.

## 4. Styling

- New lab notes use the shared theme: `#import "/templates/theme.typ": *` and
  `#show: theme.with(course: "…")`.
- Some existing lab notes in a repo are **intentionally hand-styled** (their own
  background and title block). Leave them alone unless asked.
- The complete-notes generator includes theme-based notes directly, but wraps
  standalone notes in a white appendix page. A theme-based note must therefore
  emit its own `#note-title` so it appears in the table of contents.

## 5. Quality bar

- [ ] The aim, method, results and analysis are all present and in order.
- [ ] Every result has a figure or table, and the text explains it.
- [ ] Any handout questions are answered explicitly.
- [ ] The explanation connects the result to the underlying theory.
- [ ] Figures are cropped, named, captioned and referenced.
- [ ] Compiles: `typst compile --root <repo> "<note>.typ"`.
- [ ] A reader could reproduce the lab and understand the result from the note.
