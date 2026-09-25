---
name: lecture-notes
description: Turn lecture slides, recordings, transcripts, or readings into high-yield Typst study notes. Use whenever the user is converting lecture or course material into notes, study guides, or a topic summary. The result must be a learning resource that explains, connects, compresses, and self-tests — never a transcript or a re-typed copy of the slides.
---

# Lecture → study notes

These Typst documents are a **learning instrument, not a copy of the slides**. The
user already has the slides and can read them faster than a re-typed version. The
notes exist to do what slides cannot: explain the reasoning, connect ideas,
compress ruthlessly, and let the reader test themselves.

**The one-line test:** if the notes are mostly the slides re-typed or reordered,
they are wrong.

## The job

Reconstruct the *argument* of the lecture, not its running order:

- **Organise by concept, not by slide.** Merge slides that repeat one point; split
  a dense slide into the ideas it actually contains. The slide order is an
  artefact of the lecture, not a good structure for learning.
- **Explain the "why".** Every fact, formula, or definition gets the mechanism,
  reasoning, or purpose the lecturer said out loud but the slide only gestured at.
- **Generate, don't copy.** Write it in the user's own words; derive the result;
  work the example. Verbatim bullet dumps are the failure mode.
- **Be concrete.** Every abstract idea gets at least one example and, where it
  helps, a non-example or edge case.
- **Make it testable.** Add active-recall prompts, not just statements.
- **Compress hard.** Cut fluff (below) and keep only what changes understanding.

## Strip this (fluff)

- Admin and logistics: assessment dates, "any questions?", textbook page
  references, course housekeeping.
- Slide furniture: title-only slides, section dividers, "Agenda", "Recap" lists
  that don't teach, repeated branding.
- Decorative images and stock photos that carry no information.
- Duplicated or near-duplicated slides.
- Anything already assumed as a prerequisite.

## Keep and add this (substance)

- The core question the lecture answers and why it matters.
- Precise definitions plus a plain-English restatement.
- Mechanisms and causal chains (how X leads to Y), not just X and Y.
- Contrasts: X vs Y, and when to use each.
- Procedures as numbered steps (`step` / `steps`).
- Formulas with the meaning of each symbol and when to reach for them.
- Worked examples that show the reasoning, not just the answer.
- Common mistakes, misconceptions, and exam traps (`warn`).
- Connections to earlier topics and the wider course.
- A small number of self-test questions with answers (`qa`).

## Method (evidence-based)

1. **Survey** the source first and list the concepts it covers.
2. **Turn each concept into a question** — these become your section headings and
   your retrieval prompts.
3. **Explain why / how** for each one (elaborative interrogation).
4. **Write it yourself** rather than copying (the generation effect).
5. **Attach a concrete example** and, where useful, one visual (concrete examples +
   dual coding).
6. **Add a self-test** at the end of each section with a `qa` block (retrieval
   practice / active recall).
7. **Link related concepts** so they can be reviewed together (interleaving and
   spaced review).

This is not busywork: retrieval practice, elaboration, generation, concrete
examples, dual coding, and interleaving are the techniques with the strongest
evidence behind them for durable learning.

## Suggested structure

Use the user's snippet library for all styling (see the `typst-snippets` skill);
do not invent markup. A typical set of notes:

1. Page preamble (`page` snippet), title block, course, date.
2. **Big picture** — one short paragraph: the mental model for the topic.
3. **Objectives as questions** — "By the end you can …", phrased so each is
   answerable (use a `card`).
4. **One section per concept**, in a logical order:
   - `def` callout — precise definition + plain restatement;
   - prose — the mechanism / why;
   - `ex` callout — a concrete or worked example;
   - `warn` callout — the common mistake or exam trap;
   - `qa` block — one or two active-recall questions.
5. **Key takeaways** — 3–6 compressed points (`key` callout), not a recap of every
   slide.
6. **Open questions / review** — gaps to resolve and links to related topics.

Adapt this to the subject: a proof-heavy topic leans on `thm`/`proof`; a
systems topic on `circuit`/`cetz`; an algorithms topic on `bigo` + `cbsql`/`cbpy`.

## Quality bar (check before finishing)

- Could a student who missed the lecture learn the topic from this alone?
- Is every claim explained, or merely asserted?
- Is there at least one example per abstract idea?
- Is there at least one self-test per concept?
- Could you cut 20% without losing meaning? If so, cut it.
- Does it read as a coherent explanation, or as disconnected slide bullets?
- Are the facts faithful to the source? Never invent content; mark genuine
  uncertainty as an open question instead.

## Anti-patterns

- Slide-per-section, verbatim bullets, "Agenda" and "Recap" filler.
- Definitions with no example; formulas with no interpretation.
- Decorative diagrams, or screenshots where a clean `cetz`/`mmd` diagram belongs.
- Walls of prose that can't be skimmed, or bullet lists that can't be read as prose.
- Presenting outside material as if it were in the lecture.
- Padding: length is not effort; density of meaning is.
