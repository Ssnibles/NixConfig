---
name: ebook-library
description: Curate a Calibre library or Kobo reader. Use when reading, auditing, standardising or bulk-editing ebook metadata, tags, collections (shelves), series, authors, identifiers or formats, when reconciling the library against the device, when a series' cover art does not match, or when a title looks misattributed or misfiled.
---

# Ebook library curation

Load this skill before touching a Calibre library or a Kobo reader. Read the
reference file for whichever database you are about to edit.

- `references/calibre.md` for `metadata.db`, its schema, and the SQL traps.
- `references/kobo.md` for `KoboReader.sqlite` and shelf mirroring.
- `references/covers.md` for making a series' artwork match.
- `references/taxonomy.md` for the controlled vocabularies to reuse.

## Two layers, two jobs

Treat tags and collections as separate systems.

**Tags describe the book.** Genre, sub-genre, subject, notable elements,
audience, form. They exist to be searched and filtered.

**Collections are what a bookshop would call a section.** They exist so you can
browse when you do not yet know what you want.

Do not let either do the other's job. A shelf named for a feeling is not
browsable, because nobody agrees on what belongs there. A tag that repeats a
shelf name is dead weight, because the shelf already answers it.

## Rules for tags

- Settle the vocabulary once, then only ever use those words.
- Title case, no trailing punctuation, no plurals.
- Describe content, not publication. Drop imprint names, language names,
  character-name headings, and `Read` markers.
- Keep one of each near-duplicate. `Fiction`, `Literary Fiction` and
  `Literature & Fiction` are the same idea written three ways.
- Drop identity markers such as `LGBTQ+` unless the user asks for them. People
  do not browse by them.
- Drop a tag that is a strict subset of another. `Detective` belongs inside
  `Mystery`.
- Keep a one-book tag only when the user would genuinely search for it.
- Aim for 4 to 8 tags per book.

## Rules for collections

- Name them the way a bookshop labels a section: `Crime & Mystery`, `Historical
  Fantasy`, `Classics`. Plain words, no mood poetry.
- Let a book sit on several shelves. Overlap is what browsing needs.
- Use enough shelves to be useful and no more. Roughly one per 5 to 10 books.
- No catch-alls. If one shelf holds most of the library, split or drop it.
- Never ship a typo. `Yound Adult` and `Philosphy` survive on devices for years.
- Keep practical shelves only when they earn their place, such as `Omnibus`
  for boxed sets.

## Workflow

1. Back up `metadata.db` and, if the reader is mounted, `.kobo/KoboReader.sqlite`.
   Keep both paths for the final reply.
2. Dump every book with its tags, collections, series, rating and identifiers.
   Read the description of any book you cannot place with confidence.
3. Build the vocabulary first, then a table of book id to tags to collections.
4. Check the table before applying it:
   - every book appears once, with no duplicate ids,
   - no book is left with zero shelves,
   - every value is already in the vocabulary.
5. Apply to Calibre, then mirror the shelves to the device.
6. Verify: integrity check, orphan check, and a per-book comparison of Calibre
   collections against device `ShelfContent`.

## Series covers

New books bought as a series almost never share cover art. Each one carries
whatever edition the shop had, so a shelf of six shows four designs. Nobody
complains about a single book's cover, but they always notice a mismatched row.

Read `references/covers.md` before sourcing anything. The short version: find
which design you already have most of, fetch the rest in that design, and change
both `cover.jpg` and the cover inside the epub.

## Auditing beyond tags

Run these checks on any library you are asked to tidy.

| Check | What it catches |
|---|---|
| Titles with `: A Novel`, all caps, or 60+ characters | Store copy pasted into the title field |
| Series with one book, or named after its own book | Fake series |
| Series that is really a publisher imprint | Vendors writing into the series field |
| Author names starting `Dr`, `Prof`, or containing `|` | Titles in names, commas split into separators |
| Duplicate author rows differing only in punctuation | Same person filed twice |
| Identifier types that are dead or one-off | `epubbud`, `uri`, `urn`, `kobo` |
| Formats the device cannot read | `MOBI` beside `KEPUB` on a Kobo |
| `ORIGINAL_EPUB` beside `EPUB` | Calibre's own pre-conversion safety copy |
| Books in `.caltrash` | Deleted material still taking space |
| Device rows with `IsDownloaded = false` and GUID ids | Store records never downloaded |
| Series covers of differing design or image size | Different editions mixed into one series |
| The same book on the reader under two paths | A rename stranded the earlier upload |

Report the disk saved and the record counts. Do not narrate the edits.

## Safety

- Never edit either database while Calibre is running. It writes its cached
  copy back on exit and silently undoes your work.
- Back up before the first statement, not after.
- Do not delete files, store records, or the trash without asking first. Offer
  it, then wait.
- A half-fixed book is worse than an untouched one. If you change an author or
  a title, say plainly that the folder name and the device copy still disagree,
  and what will reconcile them.
- Renaming an author or a title strands the old file on the reader. Kobo tracks
  a book by its path, so Calibre uploads a second copy and the book shows twice.
  Delete the stale copy in the same session, or warn that it will appear. The
  recipe is in `references/kobo.md`.
