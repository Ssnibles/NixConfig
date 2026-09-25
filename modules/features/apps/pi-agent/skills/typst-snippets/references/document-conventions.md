# Document conventions

The checklist for any Typst document written for this user. Read it before
writing or restructuring a document. `SKILL.md` covers the snippet mechanics;
this file covers the choices around them.

## 1. Always start from the `page` preamble

- Reproduce the `page` snippet verbatim and do not reorder or trim it.
- It defines `theme`, `page-type`, `course`, `date`, the colours (`text-color`,
  `stroke-color`, `bg-color`), the UI tokens (`ui-radius`, `ui-radius-sm`,
  `ui-border`, `ui-surface`, `ui-surface-raised`), `mmdr-theme`, and the `#show`
  rules. Everything else assumes it exists.
- Never redefine those variables locally or hardcode their values.

## 2. Document metadata

- Give the document a title: either `#set document(title: "…")` or exactly one
  `= ` level-1 heading (the running header falls back to it).
- Set `course` and `date` in the preamble (the `page` snippet provides both).
- `page-type: "notes"` = self-study notes (header on every page, level-3
  headings, date title block). `page-type: "lecture"` = lecture handout
  (numbered footer, larger title block). Pick one and keep it.

## 3. Structure

- **One `=` (h1) per document.** It is the topic, not a section.
- `==` (h2) for each major concept; `===` (h3) for sub-points; do not skip
  levels. Use `====`+ only when genuinely needed.
- Order sections by **concept dependency**, not by the order they appeared in
  the slides.
- One idea per section. If a heading needs "and", it is probably two sections.
- Use `#pagebreak()` only between major topics, not between every section.
- Put related things side by side with `#grid(columns: (1fr, 1fr), align:
  center + horizon, …)` — e.g. diagram + explanation, expression + truth table.

## 4. Content → snippet

| Content | Snippet |
|---|---|
| Definition | `def` / `definition` |
| Theorem / lemma / corollary / proposition | `thm` / `lem` / `cor` / `prop` |
| Proof | `proof` |
| Worked example | `ex` / `example` |
| Mistake, trap, caution | `warn` / `warning` / `caution` |
| Shortcut | `tip` |
| Aside | `note` / `info` |
| Emphasis / danger | `important` / `danger` |
| Summary point | `key` / `takeaway` |
| Exercise / question / solution | `question` / `prob` / `sol` |
| Tangential remark | `rem` / `remark` |
| Answer-and-question recall | `qa` |
| Numbered procedure | `step` / `steps` |
| Term + definition line | `kv` / `term` |
| Comparison / truth table | `tbl` / `tbl3` / `tbl4` / `truthtable` |
| Algorithm cost | `bigo` |
| Code | `cb*` / `codeshow` / `ic` |
| Diagram | see §7 |
| Callout of any colour | `callout` |
| Tag / label | `badge` |

For a full listing of every trigger, grep the bundled `references/typst.lua`
(`grep -n 'trig = "' ...`).

## 5. Math

- Inline math with `$...$` for symbols inside a sentence; display math with
  `$ ... $` on its own.
- Use **Typst math names**, never LaTeX: `<=`, `>=`, `!=`, `arrow`, `RR`,
  `infinity`, `in`, `subset`, `union`, `intersection`, `nothing`, `therefore`,
  `because`, `forall`, `exists`, greek names (`alpha`, `theta`, …).
- Multi-line derivations use the `eq` / `eqalign` snippets, aligned on `&=`.
- Define each symbol on first use.
- Keep display equations on their own line; do not bury them in a paragraph.

## 6. Code

- Fence code with the language tag (`cbpy`, `cbnix`, …). Put the filename on the
  first line of the block when a header is wanted; the `codeshow`/`rawshow` rule
  treats a first line without spaces as a filename.
- Apply `codeshow` (or `rawshow`) once per document if the document contains
  code, otherwise blocks render as plain raw.
- Inline identifiers use `ic` (`` `code` ``).

## 7. Diagrams

See `SKILL.md` → "Diagrams" for the tools, imports, and templates. The rules:

- **All diagrams are code-generated.** Never paste a screenshot or photo unless
  the figure is inherently an image (software UI, a photograph, a scan).
- **Mermaid-modelled → `mmdr`** (flowcharts, sequence, state, class, ER, Gantt,
  pie, git graphs). Less error-prone than hand-placing coordinates.
- **Everything else → CeTZ**, and **logic circuits → Zap**.
- Add the import for the tool you use at the very top of the file
  (`cetzsetup` / `mmdsetup` snippets). `mmdr` diagrams must pass
  `theme: mmdr-theme`.
- Wrap each diagram in `#figure(caption: [...])[...]`, centre it, and refer to it
  in the surrounding text.
- Keep diagrams small and readable; prefer left-to-right flow.

## 8. Text and emphasis

- `*bold*` marks a key term on first use.
- `_italic_` for emphasis or foreign terms.
- `` `code` `` for identifiers, file paths, and commands.
- `-` for unordered lists; `+` for ordered steps; `kv`/`term` for term lists.
- Do not manually indent or add blank lines to fake spacing; the `#show` rules
  and `par` settings handle it.

## 9. Language and tone

- Use **New Zealand / British spelling**: `-ise`/`-isation`, `colour`, `centre`,
  `analyse`, `behaviour`, `licence` (noun).
- Write concisely; cut filler ("basically", "it is important to note that").
- Use consistent terminology for a concept throughout, matching the lecturer.
- Prefer active voice and plain language.

## 10. Colour and theme

- Never hardcode page/font/colour settings. Use `theme`, `text-color`,
  `ui-*`, and `mmdr-theme`.
- Callout accents come from the fixed palette (`#3182ce`, `#38a169`, `#db6b20`,
  `#e53e3e`, `#805ad5`, `#718096`); do not invent new ones.

## 11. Prohibited

- Adding third-party packages beyond `cetz`, `zap`, and `mmdr`.
- Overriding the font, page size, margins, or colours set by the preamble.
- Reordering or rewriting the preamble.
- LaTeX syntax (`\frac`, `\begin{…}`) or Markdown syntax (`###`, `**bold**`,
  pipe tables) in `.typ` files.
- Screenshots where a `cetz` / `mmd` diagram belongs.
- Inventing content that was not in the source (see the `lecture-notes` skill).

## 12. Continuity

- Open each topic by linking it to the previous one ("building on …").
- Reuse the same notation symbols across documents in a course.
- End each major section with takeaways and a self-test (per `lecture-notes`).

## Pre-delivery checklist

- [ ] `page` preamble present and untouched.
- [ ] One h1; heading levels not skipped.
- [ ] Every code block has a language tag; `codeshow` applied if needed.
- [ ] Every diagram imported, themed, captioned, and code-generated.
- [ ] Math uses Typst names; symbols defined.
- [ ] No hardcoded colours/fonts; no new packages.
- [ ] NZ/British spelling; consistent terminology.
- [ ] No LaTeX/Markdown syntax.
- [ ] Document compiles.
