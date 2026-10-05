// =============================================================================
// Shared theme for every Uni note.
// =============================================================================
// Single source of truth for page setup, fonts, colours, headings, code blocks,
// figure captions and the convenience helpers.
//
// A note opts in with:
//
//   #import "/templates/theme.typ": theme, note-title, callout, card, qa, uml-class
//   #show: theme.with(course: "COMPXxxx")
//
// and renders its title with `#note-title(date, title)`. Compile with
// `--root` pointing at the repository root (e.g. `typst compile --root ~/Uni …`).
// =============================================================================

#import "@preview/cetz:0.5.2"
#import "@preview/zap:0.6.0"
#import "@preview/mmdr:0.2.2": mermaid

// ── Palette and design tokens ───────────────────────────────────────────────
// Theme mode: "dark" (default) or "light". Override at compile time with
// `typst compile --input theme-mode=light …`; the complete-notes generator does
// this for you via its `--light` flag. Read here, at module load, so that every
// derived colour (and the notes' own `ui-border`/`ui-surface`/… references)
// stays a plain value rather than a context-dependent one.
#let theme-mode = sys.inputs.at("theme-mode", default: "dark")
#let text-size = 10pt

#let bg-colour = if theme-mode == "dark" { rgb("#1a1a1a") } else { rgb("#ffffff") }
#let text-colour = if theme-mode == "dark" { rgb("#e0e0e0") } else { rgb("#000000") }
#let stroke-colour = if theme-mode == "dark" { rgb("#e0e0e0") } else { black }

#let ui-radius = 6pt
#let ui-radius-sm = 3pt
#let ui-border = if theme-mode == "dark" { rgb("#2e2f38") } else { rgb("#e2e2e8") }
#let ui-surface = if theme-mode == "dark" { rgb("#1f1f26") } else { rgb("#f7f7fa") }
#let ui-surface-raised = if theme-mode == "dark" { rgb("#17171c") } else { rgb("#efeff3") }

#let font-sans = ("SF Pro Text", "Inter", "DejaVu Sans")
#let font-serif = ("New Computer Modern", "Libertinus Serif", "DejaVu Serif")
#let font-mono = ("JetBrainsMono NF", "DejaVu Sans Mono")

#let mmdr-theme = if theme-mode == "dark" {
  (
    background: "#1a1a1a",
    primary_color: "#252530",
    primary_text_color: "#e0e0e0",
    primary_border_color: "#3a3b46",
    line_color: "#a0a0a0",
    secondary_color: "#252530",
    tertiary_color: "#252530",
    text_color: "#e0e0e0",
    edge_label_background: "#1a1a1a",
    cluster_background: "#1a1a1a",
    cluster_border: "#3a3b46",
    sequence_actor_fill: "#252530",
    sequence_actor_border: "#3a3b46",
    sequence_actor_line: "#a0a0a0",
    sequence_note_fill: "#252530",
    sequence_note_border: "#3a3b46",
    sequence_activation_fill: "#252530",
    sequence_activation_border: "#3a3b46",
  )
} else {
  (
    background: "#ffffff",
    primary_color: "#f7f7fa",
    primary_text_color: "#000000",
    primary_border_color: "#e2e2e8",
    line_color: "#666666",
    secondary_color: "#f7f7fa",
    tertiary_color: "#f7f7fa",
    text_color: "#000000",
    edge_label_background: "#ffffff",
    cluster_background: "#ffffff",
    cluster_border: "#e2e2e8",
    sequence_actor_fill: "#f7f7fa",
    sequence_actor_border: "#e2e2e8",
    sequence_actor_line: "#666666",
    sequence_note_fill: "#f7f7fa",
    sequence_note_border: "#e2e2e8",
    sequence_activation_fill: "#f7f7fa",
    sequence_activation_border: "#e2e2e8",
  )
}

// Themed Zap/CeTZ circuit style: gate outlines and labels follow the page text
// colour, so circuits stay legible in both themes (Zap defaults to black on white).
#let zap-theme = (
  variant: "ieee",
  stroke: 0.8pt + text-colour,
  node: (stroke: 0.65pt + text-colour, fill: text-colour, nofill: bg-colour),
  wire: (stroke: 0.6pt + text-colour),
)

// Language metadata: nerd font devicon + file extension
#let lang-meta = (
  py:      (icon: "\u{E606}", ext: ".py"),
  python:  (icon: "\u{E606}", ext: ".py"),
  js:      (icon: "\u{E74E}", ext: ".js"),
  ts:      (icon: "\u{E628}", ext: ".ts"),
  rust:    (icon: "\u{E7A8}", ext: ".rs"),
  rs:      (icon: "\u{E7A8}", ext: ".rs"),
  c:       (icon: "\u{E61E}", ext: ".c"),
  cpp:     (icon: "\u{E61D}", ext: ".cpp"),
  java:    (icon: "\u{E738}", ext: ".java"),
  go:      (icon: "\u{E626}", ext: ".go"),
  sh:      (icon: "\u{E795}", ext: ".sh"),
  bash:    (icon: "\u{E795}", ext: ".sh"),
  html:    (icon: "\u{E736}", ext: ".html"),
  css:     (icon: "\u{E749}", ext: ".css"),
  nix:     (icon: "\u{F313}", ext: ".nix"),
  lua:     (icon: "\u{E620}", ext: ".lua"),
  sql:     (icon: "\u{E706}", ext: ".sql"),
  json:    (icon: "\u{E60B}", ext: ".json"),
  yaml:    (icon: "\u{E60B}", ext: ".yaml"),
  md:      (icon: "\u{E73E}", ext: ".md"),
  asm:     (icon: "\u{E637}", ext: ".asm"),
  hs:      (icon: "\u{E777}", ext: ".hs"),
  php:     (icon: "\u{E73D}", ext: ".php"),
  xml:     (icon: "\u{E8EA}", ext: ".xml"),
  verilog: (icon: "\u{F2DB}", ext: ".v"),
  v:       (icon: "\u{F2DB}", ext: ".v"),
  tcl:     (icon: "\u{EAC4}", ext: ".tcl"),
  gradle:  (icon: "\u{E7F2}", ext: ".gradle"),
  cs:      (icon: "\u{E7B2}", ext: ".cs"),
  csharp:  (icon: "\u{E7B2}", ext: ".cs"),
  http:    (icon: "\u{F0AC}", ext: ".http"),
  txt:     (icon: "\u{F15C}", ext: ".txt"),
  toml:    (icon: "\u{E6B2}", ext: ".toml"),
  dockerfile: (icon: "\u{E7B0}", ext: ""),
  kotlin:  (icon: "\u{E81B}", ext: ".kt"),
  swift:   (icon: "\u{E755}", ext: ".swift"),
  r:       (icon: "\u{E895}", ext: ".r"),
)

#let inline-code-bg = state("inline-code-bg", ui-surface)
#let inline-code-fg = state("inline-code-fg", text-colour)

// When the complete-notes generator assembles a paper it passes
// `--input stitched=true`; the generated wrapper then applies the theme once
// (with `force: true`) and the included notes skip it, so the `show raw` rule
// and page setup are not stacked (which would double inline-code backgrounds).
#let _uni-notes-stitched = sys.inputs.at("stitched", default: "false") == "true"

// Line numbers for block code. **On by default.** Toggle them globally for the
// rest of a document with `#code-line-numbers.update(false)` / `(true)`, or
// override a single block with the `#noln[…]` / `#ln[…]` wrappers below.
#let code-line-numbers = state("code-line-numbers", true)

// Per-block overrides. Wrap a fenced code block, e.g.
//   #noln[```py … ```]      #ln[```py … ```]
#let noln(body) = {
  [#code-line-numbers.update(false)]
  body
  [#code-line-numbers.update(true)]
}

#let ln(body) = {
  [#code-line-numbers.update(true)]
  body
  [#code-line-numbers.update(false)]
}

// A first line is a filename only if it looks like one (`main.rs`, `schema.sql`).
// This stops code like `<?php` or `<div>` from being swallowed as a filename.
#let _is-filename(s) = s.match(regex("^[A-Za-z0-9_][A-Za-z0-9_.\\-/]*\\.[A-Za-z0-9]+$")) != none

// Some languages (PHP) only highlight inside their open tag, so a `php` block
// without `<?php` renders plain. Re-create it with a hidden opener (dropped
// again below) to get highlighting without changing the note's content.
#let _php-opener = "<?php /*__uni-notes-php__*/"

// ── Keep-together helper ────────────────────────────────────────────────────
// Wrap content in a block that stays on one page when it fits: instead of
// splitting and leaving one or two orphan rows, the whole block moves to the
// next page. Content taller than a page can't be kept together, so it is
// allowed to break (a table with `table.header` rows repeats its header).
#let keep-together(body, ..style) = context {
  let m = page.margin
  let avail-w = page.width - m.left.length - m.right.length - (m.left.ratio + m.right.ratio) * page.width
  let avail-h = page.height - m.top.length - m.bottom.length - (m.top.ratio + m.bottom.ratio) * page.height
  let probe = block(..style, body)
  // 2pt tolerance: if it only *just* fits, prefer breaking over overflowing.
  block(..style, breakable: measure(probe, width: avail-w).height > avail-h - 2pt, body)
}

// Styled code blocks: background with language + filename header, plus inline
// code pills. Applied by `theme()`.
#let raw-style(it) = {
  let lang = if it.lang != none { it.lang } else { "" }
  let lines = it.text.split("\n")

  if lang == "php" and it.block and not lines.any(l => l.contains("<?php")) {
    let first = lines.first()
    let head = if _is-filename(first) { first + "\n" } else { "" }
    let body = if _is-filename(first) { lines.slice(1).join("\n") } else { it.text }
    // The nested raw is shown inside this rule, where the code size is already
    // in effect; reset it to the body size so the block's `0.9em` isn't applied
    // a second time (which would make re-highlighted PHP blocks visibly smaller).
    set text(size: text-size)
    raw(head + _php-opener + "\n" + body, lang: "php", block: true)
  } else {
    let filename = if lines.len() > 1 and _is-filename(lines.first()) { lines.first() } else { "" }
    let meta = lang-meta.at(lang, default: (icon: "\u{F121}", ext: "." + lang))
    let display = if filename == "" { lang } else if filename.contains(".") { filename } else { filename + meta.ext }
    if it.block {
      let start = if filename != "" { 1 } else { 0 }
      // drop the hidden PHP opener injected above, if present
      let start = if start < lines.len() and lines.at(start) == _php-opener { start + 1 } else { start }
      let bodylines = it.lines.slice(start)
      let numbered = code-line-numbers.get()
      keep-together(block(
        width: 100%,
        radius: ui-radius,
        stroke: 0.5pt + ui-border,
        fill: ui-surface,
        clip: true,
        stack(
          dir: ttb,
          spacing: 0pt,
          ..if lang != "" {
            (
              block(
                width: 100%,
                fill: ui-surface-raised,
                inset: (x: 12pt, y: 6pt),
                stroke: (bottom: 0.5pt + ui-border),
                [
                  #text(font: font-mono, size: 10pt, fill: if theme-mode == "dark" { rgb("#a0a0a0") } else { rgb("#666666") })[#meta.icon]
                  #h(0.6em)
                  #text(size: 8.5pt, weight: "bold", fill: if theme-mode == "dark" { rgb("#c0c0c0") } else { rgb("#444444") })[#display]
                ]
              ),
            )
          } else { () },
          block(
            inset: (x: 12pt, y: 10pt),
            width: 100%,
            {
              set text(fill: text-colour, size: 0.9em)
              if numbered {
                grid(
                  columns: (auto, 1fr),
                  column-gutter: 0.9em,
                  row-gutter: 0.65em,
                  ..bodylines.enumerate().map(((i, l)) => (
                    align(right)[#text(fill: if theme-mode == "dark" { rgb("#565b66") } else { rgb("#9aa1ad") }, size: 0.85em)[#(i + 1)]],
                    l.body,
                  )).flatten(),
                )
              } else {
                stack(dir: ttb, spacing: 0.65em, ..bodylines.map(l => l.body))
              }
            }
          )
        )
      ))
    } else {
      box(
        fill: inline-code-bg.get(),
        inset: (x: 4pt, y: 1.5pt),
        baseline: 0%,
        radius: ui-radius-sm,
        stroke: 0.5pt + ui-border,
        text(size: 0.9em, fill: inline-code-fg.get(), it)
      )
    }
  }
}

// ── Convenience helpers (expand to the canonical snippet patterns) ──────────
#let callout(icon, title, colour, body) = keep-together(block(
  width: 100%,
  stroke: (left: 3pt + rgb(colour), rest: 0.5pt + rgb(colour + "35")),
  fill: rgb(colour + "15"),
  inset: (x: 12pt, y: 10pt),
  radius: ui-radius,
  [
    #text(weight: "bold", fill: rgb(colour))[#icon #title] \
    #v(2pt)
    #body
  ],
))

#let card(body) = keep-together(block(
  width: 100%,
  stroke: 0.5pt + ui-border,
  fill: ui-surface,
  inset: (x: 12pt, y: 10pt),
  radius: ui-radius,
  body,
))

#let qa(q, a) = [
  *Q:* #text(weight: "bold")[#q] \
  *A:* #a
]

#let uml-class(name, fields: (), methods: ()) = block(
  width: 100%,
  stroke: 0.8pt + stroke-colour,
  radius: ui-radius-sm,
  clip: true,
  stack(
    dir: ttb,
    spacing: 0pt,
    block(
      width: 100%,
      fill: rgb("#3182ce22"),
      inset: (x: 8pt, y: 5pt),
      align(center)[#text(weight: "bold")[#name]],
    ),
    block(
      width: 100%,
      stroke: (top: 0.8pt + stroke-colour),
      inset: (x: 8pt, y: 6pt),
      text(size: 8.5pt, stack(dir: ttb, spacing: 0.45em, ..fields)),
    ),
    block(
      width: 100%,
      stroke: (top: 0.8pt + stroke-colour),
      inset: (x: 8pt, y: 6pt),
      text(size: 8.5pt, stack(dir: ttb, spacing: 0.45em, ..methods)),
    ),
  ),
)

// ── Note title ──────────────────────────────────────────────────────────────
// Date top-left, then a real level-1 heading so the title is outlined, linkable
// and bookmarked. The `[TOC]` supplement marks it as a complete-notes entry
// (the outline targets only these, ignoring any stray level-1 headings inside a
// note). The heading is styled by `theme()`'s level-1 show rule.
// Grey proof block, matching the `proof` snippet.
#let proof(body) = keep-together(block(
  width: 100%,
  stroke: (left: 3pt + rgb("#718096"), rest: 0.5pt + rgb("#71809635")),
  fill: rgb("#71809612"),
  inset: (x: 12pt, y: 10pt),
  radius: ui-radius,
  [
    #text(weight: "bold", fill: rgb("#718096"))[∎ Proof:] \
    #v(2pt)
    #body #h(1fr) $square$
  ],
))

// Blue "Big-O" complexity card, matching the `big-o` snippet.
#let bigo(title, body) = keep-together(block(
  width: 100%,
  stroke: (left: 3pt + rgb("#3182ce"), rest: 0.5pt + rgb("#3182ce35")),
  fill: rgb("#3182ce15"),
  inset: (x: 12pt, y: 10pt),
  radius: ui-radius,
  [
    #text(weight: "bold", size: 12pt, fill: rgb("#3182ce"))[⚡ Big-O: #title]
    #v(0.4em)
    #body
  ],
))

#let note-title(date, title) = [
  #align(center)[
    #set par(justify: false)
    #text(size: 9.5pt, font: font-serif, fill: rgb("#718096"))[#date]
  ]
  #v(0.75em)
  #heading(level: 1, outlined: true, bookmarked: true, supplement: [TOC])[#title]
]

// ── The theme itself ────────────────────────────────────────────────────────
#let theme(course: "", page-type: "notes", force: false, body) = {
  if _uni-notes-stitched and not force {
    // The assembled complete-notes file already applied the theme.
    body
  } else {
    set page(
    paper: "a4",
    margin: (x: 2.5cm, top: 3cm, bottom: 3cm),
    fill: bg-colour,
    header: if page-type == "notes" { context {
      let page_num = counter(page).get().first()
      if page_num > 1 {
        set text(size: 8.5pt, font: font-serif, fill: text-colour, hyphenate: false)
        let h1_on_page = query(heading.where(level: 1)).filter(h => h.location().page() == page_num)
        let doc_title = if document.title != none {
          document.title
        } else if h1_on_page.len() > 0 {
          h1_on_page.first().body
        } else {
          let before = query(heading.where(level: 1).before(here()))
          if before.len() > 0 { before.last().body } else { [Notes] }
        }
        let left_text = if course != "" {
          course
        } else {
          let on_page = query(heading.where(level: 2)).filter(h => h.location().page() == page_num)
          if on_page.len() > 0 {
            on_page.first().body
          } else {
            let before = query(heading.where(level: 2).before(here()))
            if before.len() > 0 { before.last().body } else { [] }
          }
        }
        grid(
          columns: (1fr, 1fr, 1fr),
          align: horizon,
          align(left)[#smallcaps(left_text)],
          align(center)[#smallcaps(doc_title)],
          align(right)[#str(page_num)],
        )
      }
    } } else { none },
    footer: context {
      let page_num = counter(page).get().first()
      set text(size: 9pt, font: font-serif, fill: text-colour)
      if page-type == "lecture" or page_num == 1 {
        align(center)[#str(page_num)]
      }
    },
  )

  set text(font: font-sans, size: text-size, fill: text-colour, lang: "en")
  set par(justify: true, leading: 0.65em, first-line-indent: 0pt)

  // All headings use the serif display font
  show heading: set text(font: font-serif)

  // Level 1: centred title (date is rendered above by `note-title`).
  // NB: `#set par(justify: false)` must sit *inside* the `#align(center)` — placed
  // before it, the document's `justify: true` silently stops the centring.
  show heading.where(level: 1): it => block(above: 0em, below: 1.4em, width: 100%)[
    #align(center)[
      #set par(justify: false)
      #text(size: 20pt, weight: "bold", font: font-serif, fill: text-colour, hyphenate: false)[#course: #it.body]
    ]
  ]

  // Level 2: Bold small-caps section title with a rule filling to the margin
  show heading.where(level: 2): it => block(above: 1.8em, below: 1.2em)[
    #grid(
      columns: (auto, 1fr),
      column-gutter: 0.8em,
      align: horizon,
      text(weight: "bold", font: font-serif, fill: text-colour)[#smallcaps[#it.body]],
      line(length: 100%, stroke: 0.8pt + stroke-colour),
    )
  ]

  // Level 3: Bold italic subsection title (notes only)
  show heading.where(level: 3): it => if page-type == "notes" {
    block(above: 1.4em, below: 0.8em)[
      #text(size: 11pt, weight: "bold", style: "italic", font: font-serif, fill: text-colour)[#it.body]
    ]
  } else { it }

  // Figure captions: smaller, italic, muted grey
  show figure.caption: set text(size: 0.85em, style: "italic", fill: rgb("#718096"))

  // Underline links
  show link: underline

  // Styled code blocks and inline code
  show raw: raw-style

  // Tables keep themselves on one page whenever they fit: instead of leaving
  // one or two orphan rows at the bottom of a page, the whole table moves to
  // the next page. A table taller than a page may still break (repeat its
  // header with `table.header`).
  show table: it => keep-together(it)

    body
  }
}
