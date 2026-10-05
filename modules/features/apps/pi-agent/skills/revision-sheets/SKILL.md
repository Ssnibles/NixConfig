---
name: revision-sheets
description: Compress a course, topic, or set of notes into a dense one-page revision sheet or an active-recall question bank. Use whenever the user asks for a cheat sheet, cram sheet, summary, one-pager, or spaced-repetition questions. The result must maximise recall per page, not merely re-summarise the notes.
---

# Course / topic → revision sheet

A revision sheet is **maximum recall per page**. It is not a shortened set of
lecture notes: it drops explanation and examples and keeps the *triggers* —
definitions, formulas, contrasts, procedures, and traps — in a form you can scan
and self-quiz from.

**The one-line test:** if you can cut a line without losing a fact you might be
asked for, cut it.

Styling comes from `typst-snippets` (load it). For the full explanatory treatment
use `lecture-notes`; for worked exam answers use `test-notes`.

## 1. Two modes

Ask which is wanted, or do both:

- **Cram sheet** — one page per topic (or one page total), high-density reference.
- **Question bank** — active-recall prompts with answers hidden below, ordered by
  topic, for spaced repetition.

## 2. Build it from the learning outcomes

- List the topics the assessment actually covers (from the course outline, past
  papers, or the notes).
- For each topic, extract only: definitions, formulas, contrasts, procedures,
  common traps. Everything else is dropped.
- Order topics by dependency, not by lecture order.

## 3. Cram-sheet layout

- Use the fullest layout the theme allows: `#grid` with two or three `1fr`
  columns, `#table` for contrasts and symbol tables, `#callout` only for traps.
- One line per fact. Lead with the term.
- Keep a **formula section** per topic, defining every symbol on first use.
- Mark the highest-yield items with a `#badge` or bold so the eye lands on them.
- No prose paragraphs, no worked examples longer than one line.

```typst
#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  [
    *Singleton* — one instance, global access \
    *Adapter* — wrap an incompatible interface \
    *Observer* — one-to-many change notification
  ],
  [
    *Push* — data travels with the notification \
    *Pull* — observer fetches via a getter \
    *Blob* — overgrown class anti-pattern
  ],
)
```

## 4. Question-bank layout

- One `#qa` per prompt, grouped under topic headings.
- Cover the answers, attempt recall, then check — that is the point.
- Mix question types: define, contrast, apply, spot-the-error.
- Keep answers to one idea; if an answer has three parts, split into three prompts.

## 5. Spaced repetition

- Number the topics; revisit on an expanding schedule (day 1, 3, 7, 14…).
- Mark prompts you miss and re-test those first.
- Regenerate the sheet after each pass, dropping what you now know cold.

## 6. Quality bar

- [ ] Every learning outcome for the assessment is covered.
- [ ] Cram sheet fits its target page count when compiled (check the PDF).
- [ ] Every formula has its symbols defined; every contrast is complete.
- [ ] No filler, no repetition, no examples longer than necessary.
- [ ] Question bank answers are hidden/one-idea each.
- [ ] Compiles: `typst compile --root <repo> "<sheet>.typ"`.
