---
name: assignment-report
description: Turn assignment briefs, specifications, or project requirements into structured write-ups, reports, or design documents. Use whenever the user is drafting an assignment, project report, design document, or answering an assessment brief. The result must address every requirement and mark-scheme item, not just describe the topic.
---

# Brief → assignment write-up / report

An assignment write-up is **an argument addressed to the marker**: it shows that
every requirement in the brief has been met, and explains the decisions behind the
work. A report is organised around the mark scheme, not around the order the brief
happened to use.

**The one-line test:** if a requirement or mark-scheme item cannot be found in the
write-up, it is missing.

Styling comes from `typst-snippets` (load it). This skill is about the *content and
argument* of a graded document; `lab-notes` covers a lab record, and
`lecture-notes`/`test-notes` cover revision material.

## 1. Read the brief and the mark scheme first

- Extract the brief (`pdftotext`) and render any rubric/table pages to images
  (`pdftoppm -png -r 150`) so nothing is missed.
- Turn the brief into an explicit checklist of **deliverables and marks**. This is
  the spine of the document; every item gets a home.
- Note the constraints up front: word/page limit, required file names, submission
  format, referencing style, group vs individual, AI-use policy.

## 2. Structure

1. **Header** — course, assignment number, title, and author as the course
   requires.
2. **Big picture** (`#card`) — the brief in one sentence and what is being
   delivered.
3. **Requirements map** — a table of *Requirement / Marks / Where addressed*. Fill
   it in as you go; it doubles as the marker's index.
4. **Body, organised by requirement** (not by the brief's order):
   - **Design / approach** — the model or architecture, with diagrams
     (`#uml-class`, CeTZ, mmdr) and the reasoning for key choices.
   - **Implementation** — what was built, with short, referenced code listings.
   - **Testing / evidence** — results, test tables, outputs, measurements.
   - **Discussion / evaluation** — trade-offs, limitations, what you would change.
5. **References** — if required, in the course's style (see §5).
6. **Appendices** — full code, raw data, or long derivations that would interrupt
   the argument.

## 3. Writing

- Lead with the answer or decision, then justify it. Markers skim.
- Use the mark scheme's vocabulary so the mapping is obvious.
- NZ/British spelling; expand acronyms on first use; define symbols.
- Prefer tables/diagrams over long prose where they carry the same information.
- Keep code listings short and purposeful; reference the file and the point, and
  put the full listing in an appendix if needed.

## 4. Academic integrity

- Cite every external idea, quote, or code fragment.
- Do not paste AI-generated text unedited; make it yours and follow the course's
  AI-use policy, acknowledging use where required.
- Never fabricate results, references, or test output.

## 5. Referencing

Match the course's required style. If none is given, Harvard is a safe default:
author, year, title, source, and a full reference list. Keep one citation style
throughout; the theme has `#cite`/`#bibliography` support if a bibliography is
wanted.

## 6. Quality bar

- [ ] Every requirement and mark-scheme item is addressed and findable.
- [ ] The constraints (word limit, naming, format) are respected.
- [ ] Claims are justified, not just asserted.
- [ ] Diagrams and code are captioned, referenced and legible.
- [ ] Sources are cited; AI use is acknowledged per policy.
- [ ] Compiles: `typst compile --root <repo> "<report>.typ"`.
- [ ] A marker can award every mark without hunting.
