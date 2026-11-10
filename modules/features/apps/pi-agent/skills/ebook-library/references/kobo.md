# Kobo reader internals

## Layout

```text
/mnt/onboard/                 # or /run/media/<user>/KOBOeReader
├── .kobo/KoboReader.sqlite   # the device database
├── .kobo-images/
└── <Author, Name>/<Title> - <Author>.kepub.epub
```

Mount it wherever udisks puts it. Check `mount | grep -i kobo` rather than
guessing.

## Tables

| Table | Holds |
|---|---|
| `content` | every book, chapter, preview and store record |
| `Shelf` | one row per collection |
| `ShelfContent` | shelf name to content id, the real membership |
| `Bookmark` | highlights and annotations, often empty |
| `ratings` | usually empty, Kobo keeps ratings elsewhere |

## Reading the content table

- `ContentType = '6'` is a book. Other values are chapters, previews and
  navigational rows.
- Chapter rows have `!!` inside `ContentID`. Filter them out:
  `ContentID NOT LIKE '%!!%'`.
- `ContentID` is the key. For a sideloaded kepub it looks like
  `file:///mnt/onboard/Bardugo, Leigh/Dead Beat - Leigh Bardugo.kepub.epub`.
  Match on this, never on title.
- `content.BookshelfTags` is usually empty. `ShelfContent` is the real answer.

## The phantom records

A reader can list more books than it holds. Rows with
`IsDownloaded = 'false'` and a bare GUID `ContentID` are store records for
titles that were never downloaded. They have no file and no shelf rows.

```bash
sqlite3 .kobo/KoboReader.sqlite \
  "select IsDownloaded, count(*) from content where ContentType='6' group by 1;"
```

Reconciling the two counts is usually the first thing to explain:

```
true  = books actually on the device
false = store records, never downloaded
```

Do not delete those rows without asking. They are titles the user owns and may
want to download, and Kobo tends to re-add them at the next wifi sync.

## Rewriting shelves

`Shelf` columns: `CreationDate, Id, InternalName, LastModified, Name, Type,
_IsDeleted, _IsVisible, _IsSynced`. Use `Type = 'UserTag'` and `Id` equal to the
name.

`ShelfContent` columns: `ShelfName, ContentId, DateModified, _IsDeleted,
_IsSynced`.

Write directly against an attached database instead of generating SQL strings.
Shelf names contain `&` and apostrophes, and string escaping is where this goes
wrong.

```sql
ATTACH '/run/media/josh/KOBOeReader/.kobo/KoboReader.sqlite' AS k;
BEGIN;
CREATE TEMP TABLE map AS
  SELECT b.id AS bid, c.ContentID AS cid
  FROM books b JOIN k.content c
    ON c.ContentType='6' AND c.ContentID NOT LIKE '%!!%'
   AND c.Title = b.title;

DELETE FROM k.ShelfContent;
DELETE FROM k.Shelf;

INSERT INTO k.Shelf (CreationDate,Id,InternalName,LastModified,Name,Type,_IsDeleted,_IsVisible,_IsSynced)
  SELECT strftime('%Y-%m-%dT%H:%M:%SZ','now'), v.value, v.value,
         strftime('%Y-%m-%dT%H:%M:%SZ','now'), v.value,
         'UserTag','false','true','false'
  FROM (SELECT DISTINCT c.value AS value FROM books_custom_column_1_link l
        JOIN custom_column_1 c ON c.id=l.value) v;

INSERT INTO k.ShelfContent (ShelfName,ContentId,DateModified,_IsDeleted,_IsSynced)
  SELECT c.value, m.cid, strftime('%Y-%m-%dT%H:%M:%SZ','now'), 'false','false'
  FROM map m
  JOIN books_custom_column_1_link l ON l.book=m.bid
  JOIN custom_column_1 c ON c.id=l.value;
COMMIT;
```

Matching on `c.Title = b.title` is a shortcut. Titles drift, so add explicit
exceptions for any book whose title you changed, for example
`OR (b.id=75 AND c.Title='The-Metamorphosis')`.

## Verify the mirror

Compare Calibre's collections against the device per book. Zero mismatches is
the only acceptable answer.

```sql
ATTACH '/run/media/josh/KOBOeReader/.kobo/KoboReader.sqlite' AS k;
SELECT 'mismatches', count(*)
FROM books b
JOIN k.content c ON c.ContentType='6' AND c.ContentID NOT LIKE '%!!%'
 AND c.Title = b.title
WHERE (SELECT group_concat(value,'|') FROM
         (SELECT v.value AS value FROM books_custom_column_1_link l
          JOIN custom_column_1 v ON v.id=l.value WHERE l.book=b.id ORDER BY v.value))
   IS NOT
      (SELECT group_concat(ShelfName,'|') FROM
         (SELECT ShelfName FROM k.ShelfContent WHERE ContentId=c.ContentID ORDER BY ShelfName));
```

Also check the device is still sound and nothing dangles:

```bash
sqlite3 .kobo/KoboReader.sqlite "pragma integrity_check;"
sqlite3 .kobo/KoboReader.sqlite \
  "select count(*) from ShelfContent sc where not exists (select 1 from content c where c.ContentID=sc.ContentId);"
sqlite3 .kobo/KoboReader.sqlite \
  "select count(*) from ShelfContent sc where not exists (select 1 from Shelf s where s.Name=sc.ShelfName);"
```

## Device versus library

Expect the two to disagree, and explain why rather than forcing a match.

| Cause | Symptom |
|---|---|
| Store records never downloaded | Device count higher, no files |
| A Calibre book never sent | Library count higher by one |
| Title or author edited in Calibre | Device copy no longer matches by title |
| Book converted after sending | Two copies, one stale |

Tell the user which is which. Sending the missing book or letting Calibre
resend is their call, not something to do silently.

## Stale copies after a rename

Renaming an author or a title in Calibre is the most common way to litter the
reader. Kobo tracks a book by its path, so Calibre sees no match and uploads a
second copy. The old file stays, and the book appears twice with the same
shelves.

Detect it two ways, because the two copies carry different titles and a title
group-by will miss them:

```bash
# same title twice
sqlite3 .kobo/KoboReader.sqlite "select Title, count(*) from content
  where ContentType='6' and IsDownloaded='true' and ContentID not like '%!!%'
  group by Title having count(*)>1;"

# files on disk against rows in the database
sqlite3 .kobo/KoboReader.sqlite "select ContentID from content
  where ContentType='6' and IsDownloaded='true' and ContentID not like '%!!%';" \
  | sed 's|^file://||' | sort > /tmp/dbfiles.txt
find . -maxdepth 2 -name '*.kepub.epub' | sed 's|^\./|/mnt/onboard/|' | sort > /tmp/diskfiles.txt
diff /tmp/dbfiles.txt /tmp/diskfiles.txt
```

The second check is the one that catches a rename, and at the end it should be
silent with equal counts both ways. Before deleting anything, confirm which copy
is the stale one. It is usually the older file, but check the dates and the
shelf rows rather than assuming.

Removing one copy takes four steps, and the first is the easy one to miss:
**chapter rows use a different path prefix from the book row.** The book row is
`file:///mnt/onboard/...` and its chapters are `/mnt/onboard/...!!chapter.xhtml`.
A delete keyed on the book row leaves every chapter behind.

```sql
BEGIN;
DELETE FROM ShelfContent WHERE ContentId = '<book row>' OR ContentId LIKE '<chapters>%';
DELETE FROM Bookmark     WHERE ContentID = '<book row>' OR ContentID LIKE '<chapters>%';
DELETE FROM content      WHERE ContentID = '<book row>' OR ContentID LIKE '<chapters>%';
COMMIT;
```

Then delete the file, and leave the author folder alone if it holds other books.
Re-run the file and row diff, then the shelf mirror check, then
`pragma integrity_check`. A clean result is 0 rows in each direction and 0
mismatches.

## Ejecting

Shelves are read from the database at boot. Tell the user to eject properly
rather than yanking the cable, or the reader may keep the old view.
