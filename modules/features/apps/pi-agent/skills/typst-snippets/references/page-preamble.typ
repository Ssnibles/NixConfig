// Canonical expansion of the `page` snippet from references/typst.lua.
// Use this verbatim as the preamble of every document. Only `course` and
// `date` change between documents (the snippet auto-fills today's date);
// everything else is fixed. If it ever disagrees with references/typst.lua,
// the Lua file wins — regenerate, do not hand-edit.
#let theme = "dark"
#let page-type = "notes"
#let course = ""
#let date = "28 September 2026"

#let bg-color = if theme == "dark" { rgb("#1a1a1a") } else { rgb("#ffffff") }
#let text-color = if theme == "dark" { rgb("#e0e0e0") } else { rgb("#000000") }
#let stroke-color = if theme == "dark" { rgb("#e0e0e0") } else { black }

#let ui-radius = 6pt
#let ui-radius-sm = 3pt
#let ui-border = if theme == "dark" { rgb("#2e2f38") } else { rgb("#e2e2e8") }
#let ui-surface = if theme == "dark" { rgb("#1f1f26") } else { rgb("#f7f7fa") }
#let ui-surface-raised = if theme == "dark" { rgb("#17171c") } else { rgb("#efeff3") }

#let font-sans = "SF Pro Text"
#let font-serif = "New Computer Modern"

#let mmdr-theme = if theme == "dark" {
  (
    background: "#1f1f26",
    primary_color: "#252530",
    primary_text_color: "#e0e0e0",
    primary_border_color: "#3a3b46",
    line_color: "#a0a0a0",
    secondary_color: "#252530",
    tertiary_color: "#252530",
    text_color: "#e0e0e0",
    edge_label_background: "#1f1f26",
    cluster_background: "#1f1f26",
    cluster_border: "#3a3b46",
  )
} else { none }

#set page(
  paper: "a4",
  margin: (x: 2.5cm, top: 3cm, bottom: 3cm),
  fill: bg-color,
  header: if page-type == "notes" { context {
    let page_num = counter(page).get().first()
    if page_num > 1 {
      set text(size: 8.5pt, font: font-serif, fill: text-color)
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
    set text(size: 9pt, font: font-serif, fill: text-color)
    if page-type == "lecture" or page_num == 1 {
      align(center)[#str(page_num)]
    }
  },
)

#set text(font: font-sans, size: 10pt, fill: text-color, lang: "en")
#set par(justify: true, leading: 0.65em, first-line-indent: 0pt)

// All headings use the serif display font
#show heading: set text(font: font-serif)

// Level 1 heading
#show heading.where(level: 1): it => if page-type == "lecture" {
  block(below: 1.2em)[
    #text(size: 16pt, weight: "bold", font: font-serif, fill: text-color)[#it.body]
    #v(0.3em)
    #line(length: 100%, stroke: 1.2pt + stroke-color)
  ]
} else {
  block(above: 1.8em, below: 1.2em)[
    #text(size: 22pt, weight: "regular", style: "italic", font: font-serif, fill: text-color)[#it.body]
  ]
}

// Level 2: Bold small-caps section title with trailing line
#show heading.where(level: 2): it => block(above: 1.8em, below: 1.2em)[
  #box(baseline: 0%, [
    #text(weight: "bold", font: font-serif, fill: text-color)[#smallcaps[#it.body]]
    #h(0.8em)
    #box(line(length: 6cm, stroke: 0.8pt + stroke-color))
  ])
]

// Level 3: Bold italic subsection title (notes only)
#show heading.where(level: 3): it => if page-type == "notes" {
  block(above: 1.4em, below: 0.8em)[
    #text(size: 11pt, weight: "bold", style: "italic", font: font-serif, fill: text-color)[#it.body]
  ]
} else { it }

// Underline links
#show link: underline

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
)

// Styled code blocks: background with language + filename header
#show raw.where(block: true): it => {
  let lang = if it.lang != none { it.lang } else { "" }
  let lines = it.text.split("\n")
  let filename = if lines.len() > 1 and not lines.first().contains(" ") { lines.first() } else { "" }
  let meta = lang-meta.at(lang, default: (icon: "\u{F121}", ext: "." + lang))
  let display = if filename == "" { lang } else if filename.contains(".") { filename } else { filename + meta.ext }
  let bodylines = it.lines.slice(if filename != "" { 1 } else { 0 })
  block(
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
              #text(font: "JetBrainsMono NF", size: 10pt, fill: if theme == "dark" { rgb("#a0a0a0") } else { rgb("#666666") })[#meta.icon]
              #h(0.6em)
              #text(size: 8.5pt, weight: "bold", fill: if theme == "dark" { rgb("#c0c0c0") } else { rgb("#444444") })[#display]
            ]
          ),
        )
      } else { () },
      block(
        inset: (x: 12pt, y: 10pt),
        width: 100%,
        {
          set text(fill: text-color, size: 0.9em)
          stack(dir: ttb, spacing: 0.65em, ..bodylines.map(l => l.body))
        }
      )
    )
  )
}

// Inline code styling
#show raw.where(block: false): it => box(
  fill: ui-surface,
  inset: (x: 4pt, y: 1.5pt),
  baseline: 0%,
  radius: ui-radius-sm,
  stroke: 0.5pt + ui-border,
  text(size: 0.9em, it)
)

// Title block (page-type aware)
#if page-type == "lecture" [
  #align(center)[
    #text(size: 20pt, weight: "bold", font: font-serif, fill: text-color)[#course: Lecture Title]
    #text(size: 10pt, fill: text-color)[#date]
  ]
  = Overview
] else [
  = Note Title
  == Overview
]

Content here...
