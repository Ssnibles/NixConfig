---
name: test-notes
description: Turn past tests, in-class tests, exams, practice papers, quizzes, or marked questions into worked test study guides. Use whenever the user is revising from an assessment paper, going through a test or exam, or asks for a "study guide" or "revision notes" for a test. The result must answer every question on the paper with the correct answer and the reasoning — never just a topic summary or a re-typed paper.
---

# Test paper → worked study guide

A test study guide is a **complete, self-contained walkthrough of one real paper**.
The reader already owns the paper; what they lack is a reliable answer *and* the
reasoning behind it for every question. The finished guide must let them revise the
whole paper cold, without opening the original.

**The one-line test:** if any question or sub-part on the paper is missing, wrongly
answered, or unexplained, the guide is incomplete.

This skill covers **what a test guide contains**. All styling comes from the
`typst-snippets` skill (load it too); the "explain, connect, self-test" mindset
comes from `lecture-notes`. A test guide is *not* a set of lecture notes: it is
organised by **paper order**, not by concept.

## 1. Read the actual paper first

Never write a test guide from memory or from a lecture summary. Get the source.

- **Extract the text.** `pdftotext paper.pdf -`. If the poppler tools are not on
  `PATH`, they usually live under `/nix/store/*-poppler-utils-*/bin/`.
- **Read the figures.** Text extraction drops UML boxes, given code, mock-ups and
  screenshots that questions depend on. Render every page to an image
  (`pdftoppm -png -r 150 paper.pdf page`) and *read the images* to recover the
  class diagram, the code under test, and any hand-drawn sketch.
- **Enumerate the paper.** List every question and sub-part with its mark
  allocation (Q1…Q10, Q2a/b/c, Q3a/b, Q4a/b/c, …). This list is your checklist —
  the guide is not done until it is empty.

## 2. Nail the correct answers

- Where the paper or a marking schedule supplies answers, use them and say so.
- Where it does not, derive each answer from the course material, show the
  reasoning, and flag genuine ambiguity in a trap callout instead of hiding it.
- **Answer the paper as set.** If the wording is loose (for example "creating the
  Singleton instance in the class constructor" meaning *eager* initialisation),
  give the intended option and explain the precise mechanism.
- **Do not invent.** No invented questions, marks, options or facts.

## 3. Structure of the guide

Follow this shape. It mirrors the working COMPX202 Test 2 guide.

1. **Header** — theme preamble and `#note-title(date, title)` (see
   `typst-snippets`). Title it "Test N — Study Guide" or "<Paper> Test N".
2. **The big picture** (`#card`) — the marks breakdown, how many MCQs versus
   written questions, and the one mental model the paper is really testing.
3. **How the paper is laid out** — a table of *Question / Topic / Marks*.
4. **Where to spend your revision time** (`#callout("💡", …)`) — advice weighted
   by marks.
5. **Cross-cutting reference tables** — the compressed knowledge the questions
   share (for example a purpose × scope pattern map, or a terminology table),
   placed before the walkthrough so the reader has the vocabulary.
6. **Question-by-question walkthroughs, in paper order:**
   - MCQs: an answer-key table first, then one `===` section per question;
   - written questions: one `==` per numbered question, one `===` per part.
7. **Key takeaways** (`#callout("📌", …)`) — the facts to memorise.
8. **Self-test** (`#qa` pairs) — one per *concept*, not one per question.
9. **Last-minute checklist** — `- [ ]` items the reader can tick off.

## 4. MCQ format

Open with a quick answer key so the reader can self-mark before reading the
walkthrough:

```typst
=== Answer key

#block(radius: ui-radius, clip: true, stroke: 0.5pt + ui-border)[
  #table(
    columns: (auto, auto, auto),
    fill: (col, row) => if row == 0 { ui-surface-raised } else { none },
    inset: (x: 10pt, y: 6pt),
    stroke: (x, y) => (top: if y > 0 { 0.5pt + ui-border } else { none }, left: if x > 0 { 0.5pt + ui-border } else { none }),
    table.header([*Q*], [*Answer*], [*Concept tested*]),
    [1], [*c* — The Blob], [Anti-patterns],
    [2], [*c* — created up front], [Singleton eager initialisation],
    // … one row per question
  )
]
```

Then one section per question. **Restate the stem and all options verbatim** from
the paper, then give the answer and the distractor analysis:

```typst
=== Q1 — Anti-pattern: the overgrown class

#card[
  *Q1.* Which anti-pattern refers to a class that has become overly large or is
  used to gather together multiple methods that don't belong anywhere else?

  - *(a)* The SuperClass
  - *(b)* The Golden Hammer
  - *(c)* The Blob
  - *(d)* The Single Parent
]

#callout("✅", "Answer: (c) The Blob.", "#38a169")[
  <the definition or mechanism that makes this correct, in your own words>
]

#callout("📝", "Why the others are wrong:", "#3182ce")[
  - *(a)* <why it is wrong>
  - *(b)* <why it is wrong>
  - *(d)* <why it is wrong>
]
```

The distractor analysis is where the marks are won: say *why* each wrong option is
wrong, not just that it is.

## 5. Written-question format

For every part, quote the prompt with its marks, give the mark scheme, then the
full model answer:

````typst
=== Part (a) — write the adapter class (8 marks)

#callout("❓", "Question Three (a):", "#805ad5")[
  <verbatim prompt> *(8 marks)*
]

#callout("✅", "What the marker is looking for (8 marks):", "#38a169")[
  <a checklist of the marks: implements the target, wraps the adaptee,
  translates the call, …>
]

```java
PaymentAdapter.java
// the complete, compilable model answer
```

#callout("💡", "Why this is an object adapter:", "#38a169")[
  <the reasoning a strong answer shows>
]
````

For written answers:

- **Give the full model answer**, not a hint. Code must match the given interface
  exactly and be logically compilable.
- **Work the reasoning**, don't just assert it — trace the code step by step in a
  table, or calculate the values.
- **State the mark scheme** ("what the marker is looking for (N marks)").
- **Check boundaries** and call them out: e.g. the rule is `< 100000`, not `<=`.
- **Reconcile typos.** If a part says "explain your answer to c)" but means (b),
  answer the intended part and note it in a trap callout.

## 6. Callouts, colours and icons

Use the palette deliberately so the guide is skimmable:

| Purpose | Icon | Colour |
|---|---|---|
| Verbatim exam prompt | ❓ | `#805ad5` |
| Correct answer | ✅ | `#38a169` |
| Mark scheme / model answer | ✅ | `#38a169` |
| Reasoning, note, definition | 📝 / 📖 | `#3182ce` |
| Trap, gotcha, boundary | ⚠ | `#dd6b20` |
| Key takeaway / summary | 📌 | `#dd6b20` |
| Always-false / precise warning | 🛑 | `#e53e3e` |

```
#callout("❓", "Question Two (a):", "#805ad5")[ … ]
#callout("✅", "Answer: (c) …", "#38a169")[ … ]
#callout("📝", "Why the others are wrong:", "#3182ce")[ … ]
#callout("⚠", "Boundary trap:", "#dd6b20")[ … ]
#callout("📌", "Output:", "#dd6b20")[ … ]
#callout("🛑", "Two statements that are always FALSE:", "#e53e3e")[ … ]
```

## 7. Quality bar (check before finishing)

- [ ] Every question and sub-part is present, with its marks, **in paper order**.
- [ ] Every MCQ has: verbatim stem + options, the answer, the reason, and why each
      other option is wrong.
- [ ] Every written part has: verbatim prompt, mark scheme, and a full model answer.
- [ ] Code answers match the given interface exactly.
- [ ] Loose wording, typos and boundary traps are called out explicitly.
- [ ] The guide compiles: `typst compile --root <repo> "<guide>.typ"`.
- [ ] A reader who never saw the paper can answer it cold from the guide alone.
