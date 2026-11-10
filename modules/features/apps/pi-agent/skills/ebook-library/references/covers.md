# Series covers

## Why a series looks wrong

Books bought individually carry whatever edition the shop stocked. Publishers
reissue the same series every few years with new artwork, and television or film
adaptations add another design on top. Six books bought as a set will often
carry four designs, and the reader sees it immediately even though each cover
is individually correct.

The fix is never to edit one book. Pick the design you already hold most of and
bring the rest to it.

## Find the mismatches

Compare file dimensions first. A matching set almost always shares an aspect
ratio, and a differing size is a strong hint.

```bash
for id in 110 111 112; do
  p=$(sqlite3 metadata.db "select path from books where id=$id")
  echo "$id $(identify -format '%wx%h' "$p/cover.jpg")"
done
```

Dimensions alone prove nothing, because two designs can be the same size. Build
a contact sheet and look at it. This is the only reliable check.

```bash
montage -label '%f' *.jpg -tile 3x2 -geometry 200x300+8+8 -background white sheet.png
```

Then read `sheet.png` as an image. Do the same for the covers embedded inside
the epubs, which are a separate layer and often different again.

## Check both layers

A book has two covers and they are independent:

| Layer | Where | Seen by |
|---|---|---|
| `cover.jpg` in the book folder | Calibre library | Calibre's grid, and the device once Calibre sends it |
| The cover image inside the epub | The file itself | Any reader that opens the epub directly |

Replacing only `cover.jpg` leaves the file still carrying the old art, so the
job looks done in Calibre and wrong on the device. Fix both.

## Pick the design

Count which design appears most often and go with it. Prefer the most recent
rebrand, since it is the one still in print and easiest to complete.

State the choice in the reply, naming the publisher and year. It is a judgement
call and the user may prefer another set.

## Fetch the missing ones

Open Library is the reliable source. Find the work, then its editions, then the
cover for the edition you want.

```text
https://openlibrary.org/search.json?title=<title>&author=<author>&fields=title,key,isbn,publisher
https://openlibrary.org/works/<key>/editions.json?limit=200
https://covers.openlibrary.org/b/isbn/<isbn>-L.jpg
https://covers.openlibrary.org/b/id/<cover_id>-L.jpg
```

Amazon's image host also serves covers by ASIN or ISBN-10, and sometimes has one
Open Library lacks:

```text
https://images-na.ssl-images-amazon.com/images/P/<asin>.01.LZZZZZZZ.jpg
```

Avoid the Google Books API. Its free quota is small and it returns 429 quickly.

Two traps:

- **A missing cover returns HTTP 200**, not 404. The body is a 1x1 pixel. Always
  check dimensions, never the status code.
- **Open Library results are full of foreign editions.** A Hebrew, Spanish or
  French cover is useless for matching an English set. Download candidates and
  look at them before choosing.

One publisher will often not have all six books in the catalogue. The same
design is frequently shared by a sister imprint, so a Houghton Mifflin set and
an Atheneum set can be the same artwork. Follow the design, not the publisher
name in the record.

## Apply

Replace `cover.jpg` and embed the same image into the epub.

```bash
ebook-polish --cover "$p/cover.jpg" "$p/Book.epub" "/tmp/pol-$id.epub"
```

Write to a temporary file first, check it, then move it over the original.
`ebook-polish` also removes a redundant wrapper page and rewrites the manifest,
so do not hand-edit the epub instead.

## Verify

Extract the internal cover back out of the new file and compare it, rather than
trusting that the command did what it claimed.

```bash
f=/tmp/pol-110.epub
opf=$(unzip -Z1 "$f" | grep -i '\.opf$' | head -1)
unzip -p "$f" "$opf" | grep -oiE '<item[^>]*id="cover"[^>]*>'
```

Match on `id="cover"`, not on the word "cover". After polishing, many epubs keep
an old `BackCover.jpg` beside the new `cover.jpg`, and a loose grep picks the
wrong one every time.

Then montage the extracted images and look at them.

## Resolution

Covers from Open Library and Amazon are usually 333 by 500 pixels at most.
Check before promising anything:

```bash
identify -format '%f %wx%h\n' *.jpg
```

Do not upscale to fake a bigger image, and do not mix a newly fetched low
resolution cover with higher resolution originals without saying so. Report the
real size and let the user decide. 333 by 500 is enough for a six inch screen
and matches what most libraries already hold.

## Leave behind

Keep the originals. Put the old `cover.jpg` files and the old epubs somewhere
outside the library and give the user the path. Swapping cover art is reversible
only if the previous art still exists.
