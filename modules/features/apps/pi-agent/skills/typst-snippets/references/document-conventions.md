# Document conventions

The checklist for any Typst document written for this user. Read it before
writing or restructuring a document. `SKILL.md` covers the snippet mechanics;
this file covers the choices around them. For a short worked body that follows
these rules, see `references/example.typ`.

## 1. Always start from the shared theme

- A note starts with the theme import and `#note-title`, exactly as in
  `references/page-preamble.typ`:

  ```typst
  #import "/templates/theme.typ": *
  #show: theme.with(course: "COMPXxxx")

  #set document(title: "Lecture X — Title")
  #let date = "Week N"

  #note-title(date, "Lecture X — Title")
  ```

- The theme (`references/theme.typ`; `templates/theme.typ` in a notes repo)
  defines `theme`, `note-title`, `page-type`, `course`, the colours
  (`text-color`, `stroke-color`, `bg-color`), the UI tokens (`ui-radius`,
  `ui-radius-sm`, `ui-border`, `ui-surface`, `ui-surface-raised`), the font
  tokens, `mmdr-theme`/`zap-theme`, and the `#show` rules. Everything else
  assumes it exists.
- Compile with the repository as the Typst root, e.g.
  `typst compile --root ~/Uni "<note>.typ"`.
- Never redefine those variables locally or hardcode their values.

## 2. Document metadata

- Give the document a title: either `#set document(title: "…")` or exactly one
  `= ` level-1 heading (the running header falls back to it).
- Pass `course` to `theme.with(...)`; set `date` as a local before `#note-title`.
- Use `#note-title(date, title)` (or the `title` snippet) instead of hand-writing
  the title: the date sits top-left and the title is centred with hyphenation off,
  as a real level-1 heading (so it feeds the outline).
- `page-type: "notes"` = self-study notes (header on every page, level-3
  headings). `page-type: "lecture"` = lecture handout (numbered footer). Pick one
  and keep it.

## 3. Structure

- **The title is the one level-1 heading.** `#note-title` emits it; do *not* also
  write a separate `= ` heading that repeats it — that produces a double title.
  Section headings start at `==`.
- `==` (h2) for each major concept; `===` (h3) for sub-points; do not skip
  levels. Use `====`+ only when genuinely needed.
- Order sections by **concept dependency**, not by the order they appeared in
  the slides.
- One idea per section. If a heading needs "and", it is probably two sections.
- Use `#pagebreak()` only between major topics, not between every section.
- Put related things side by side with `#grid(columns: (1fr, 1fr), align:
  center + horizon, …)` — e.g. diagram + explanation, expression + truth table.

## 4. Content → snippet

The theme defines **helper functions** that emit the canonical markup. They
arrive with the `#import`; prefer them over hand-writing the raw `#block(...)`
forms:

- `#callout(icon, title, color, body)` — any callout variant, e.g.
  `#callout("📖", "Definition — …:", "#3182ce")[…]`.
- `#card(body)` — a neutral bordered card.
- `#qa(question, answer)` — the Q/A retrieval pair.
- `#uml-class(name, fields: (), methods: ())` — a UML class box (arrays).
- `#proof(body)` — the grey proof block.
- `#bigo(title, body)` — the blue Big-O complexity card.
- `#note-title(date, title)` — the title heading.

| Content | Snippet |
|---|---|
| Definition | `definition`, or `#callout("📖", …)` |
| Theorem / lemma / corollary / proposition | `theorem` / `lemma` / `corollary` / `proposition` |
| Proof | `proof` / `#proof[…]` |
| Worked example | `example` |
| Mistake, trap, caution | `warning` / `caution` |
| Shortcut | `tip` |
| Aside | `note` / `info` |
| Emphasis / danger | `important` / `danger` |
| Summary point | `takeaway` |
| Exercise / question / solution | `question` / `problem` / `solution` |
| Tangential remark | `remark` |
| Answer-and-question recall | `#qa[Q][A]` (`qa` snippet) |
| Numbered procedure | `step` / `steps` |
| Term + definition line | `key-value` / `term` |
| Comparison / truth table | `table` / `table-3` / `table-4` / `table-5` / `truthtable` / `truthtable-3` |
| Algorithm cost | `big-o` |
| Code | `code-*` / `code-inline` |
| Diagram | see §7 |
| Callout of any colour | `callout` |
| Tag / label | `badge` |
| Footnote | `footnote` |
| Table of contents | `table-of-contents` |
| Cross-referenced figure | `figure-labelled` (`@fig:label`) |

For a full listing of every trigger, grep the bundled `references/typst.lua`
(`grep -n 'trig = "' ...`).

## 5. Math

- Inline math with `$...$` for symbols inside a sentence; display math with
  `$ ... $` on its own.
- Use **Typst math names**, never LaTeX: `<=`, `>=`, `!=`, `arrow`, `real`,
  `infinity`, `in`, `subset`, `union`, `intersection`, `nothing`, `therefore`,
  `because`, `forall`, `exists`, greek names (`alpha`, `theta`, …).
- Multi-line derivations use the `equation` / `equation-align` snippets, aligned on `&=`.
- Define each symbol on first use.
- Keep display equations on their own line; do not bury them in a paragraph.

## 6. Code

- Fence code with the language tag (`code-python`, `code-nix`, `code-php`, `code-xml`, `code-verilog`, …).
  Put the filename on the first line of the block when a header is wanted; the
  block `code-raw` show rule (installed by the theme) treats a first line without
  spaces as a filename. The `lang-meta` map supplies the Nerd Font devicon and file
  extension for common languages; unknown tags fall back to a generic icon.
- The theme already installs the block- and inline-`code-raw` show rules, so do **not**
  apply `code-show-rule`/`raw-show-rule` on top of it. Those snippets are only for documents
  that do not use the theme.
- Only the **first line** is a filename, and only if it looks like one
  (`main.rs`, `schema.sql`). Code such as `<?php` or `<div>` is left as code.
- **Line numbers are on by default.** Toggle a whole document with
  `#code-line-numbers.update(false)`/`(true)` (the `line-numbers` snippet), or a
  single block with the `no-line-numbers` / `with-line-numbers` snippets: `#noln[```py … ```]` /
  `#ln[```py … ```]`.
- **PHP highlights even without `<?php`** — write the snippet as you want it shown.
- Inline identifiers use `code-inline` (`` `code` ``) — a **single** backtick pair.
  Never wrap inline code in doubled backticks (`` `` `code` `` ``): Typst parses
  that as *two* raw elements, so the pill/box is drawn twice (the classic
  "double-stacked inline code" bug). Angle brackets need no escaping inside
  single backticks: `` `<div>` `` renders fine.

## 7. Diagrams

See `references/diagrams.md` for the tools, imports, and templates. The rules:

- **All diagrams are code-generated.** Never paste a screenshot or photo unless
  the figure is inherently an image (software UI, a photograph, a scan).
- **Mermaid-modelled → `mmdr`** (flowcharts, sequence, state, class, ER, Gantt,
  pie, git graphs). Less error-prone than hand-placing coordinates.
- **Everything else → CeTZ**, and **logic circuits → Zap**.
- Add the import for the tool you use at the very top of the file
  (`cetz-setup` / `mermaid-setup` snippets). `mmdr` diagrams must pass
  `theme: mmdr-theme`.
- Wrap each diagram in `#figure(caption: [...])[...]`, centre it, and refer to it
  in the surrounding text.
- Figure captions are styled globally by the theme (smaller, italic, muted
  grey `#718096`); write the caption as plain content and do not wrap it in your
  own `#text(...)`.
- Keep diagrams small and readable; prefer left-to-right flow.

## 8. Text and emphasis

- `*bold*` marks a key term on first use.
- `_italic_` for emphasis or foreign terms.
- `` `code` `` for identifiers, file paths, and commands.
- `-` for unordered lists; `+` for ordered steps; `key-value`/`term` for term lists.
- Do not manually indent or add blank lines to fake spacing; the `#show` rules
  and `par` settings handle it.

## 9. Language and tone

- Use **New Zealand / British spelling**: `-ise`/`-isation`, `colour`, `centre`,
  `analyse`, `behaviour`, `licence` (noun).
- Write concisely; cut filler ("basically", "it is important to note that").
- Use consistent terminology for a concept throughout, matching the lecturer.
- Prefer active voice and plain language.

## 10. Colour, theme, and type

- Never hardcode page/font/colour settings. Use `theme`, `text-color`, `ui-*`,
  `font-sans`, `font-serif`, and `mmdr-theme`.
- **Body text is sans-serif** (`font-sans`): paragraphs, lists, tables, callout
  content, and the footer page number. The global `#set text(font: font-sans)`
  handles this, so do not set a body font yourself.
- **Headings and heading-like furniture are serif** (`font-serif`): h1–h5, the
  lecture title block, and the running header/footer. This is already wired up
  by the theme's `#show heading` rules and explicit overrides.
- Math is rendered in `New Computer Modern Math` regardless of the text font, so
  italic variables and display equations keep their conventional look.
- Callout accents come from the fixed palette (`#3182ce`, `#38a169`, `#dd6b20`,
  `#e53e3e`, `#805ad5`, `#718096`); do not invent new ones.

## 11. Prohibited

- Adding third-party packages beyond `cetz`, `zap`, and `mmdr`.
- Overriding the font (`font-sans`/`font-serif`), page size, margins, or colours
  set by the theme.
- Reordering or rewriting the theme or the note header.
- LaTeX syntax (`\frac`, `\begin{…}`) or Markdown syntax (`###`, `**bold**`,
  pipe tables) in `.typ` files.
- Screenshots where a `cetz` / `mermaid` diagram belongs.
- Inventing content that was not in the source (see the `lecture-notes` skill).

## 12. Continuity

- Open each topic by linking it to the previous one ("building on …").
- Reuse the same notation symbols across documents in a course.
- End each major section with takeaways and a self-test (per `lecture-notes`).

## Pre-delivery checklist

- [ ] Theme imported and applied (`#show: theme.with(course: …)`); title via `#note-title`.
- [ ] One h1 (the title); heading levels not skipped.
- [ ] Every code block has a language tag (no stray `code-show-rule`/`raw-show-rule` on top of the theme).
- [ ] Every diagram imported, themed, captioned, and code-generated.
- [ ] Math uses Typst names; symbols defined.
- [ ] No hardcoded colours/fonts; no new packages.
- [ ] NZ/British spelling; consistent terminology.
- [ ] No LaTeX/Markdown syntax.
- [ ] Document compiles.
