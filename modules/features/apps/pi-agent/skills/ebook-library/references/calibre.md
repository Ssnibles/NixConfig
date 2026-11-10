# Calibre library internals

## Layout

```text
Calibre Library/
├── metadata.db                # the source of truth
├── metadata_db_prefs_backup.json
├── <Author>/<Title> (<id>)/   # one folder per book
│   ├── <Title> - <Author>.epub
│   ├── <Title> - <Author>.kepub
│   ├── cover.jpg
│   └── metadata.opf
├── .calnotes/notes.db         # per-book notes, often empty
└── .caltrash/                 # deleted books, can be very large
```

`metadata.db` wins over `metadata.opf`. Calibre rewrites the OPF on the next
metadata edit, so stale OPFs are cosmetic. Do not hand-edit them.

## Tables that matter

| Table | Holds |
|---|---|
| `books` | title, sort, author_sort, path, series_index, uuid, last_modified |
| `authors` | id, name, sort |
| `books_authors_link` | one row per book and author |
| `tags` | id, name, link |
| `books_tags_link` | one row per book and tag |
| `custom_column_1` | the Kobo collection column, label `myshelves` |
| `books_custom_column_1_link` | one row per book and collection |
| `series`, `books_series_link` | series name and membership |
| `identifiers` | type, val, book |
| `data` | one row per format: book, format, name, uncompressed_size |
| `comments` | HTML description |
| `ratings`, `books_ratings_link` | 2 to 10, halved on the device |

Everything multi-valued lives in a link table, one row per value. There is no
comma-separated column to edit.

The collection column number follows `custom_columns.colnum`. Confirm it before
writing:

```bash
sqlite3 metadata.db "select label, name, datatype, normalized from custom_columns;"
```

## The trigger trap

Calibre registers two Python functions inside its own SQLite connection:
`title_sort()` and `uuid4()`. The `sqlite3` command line does not have them, and
these triggers depend on them:

- `books_update_trg` fires after any `UPDATE ON books`.
- `books_insert_trg` fires after any `INSERT INTO books`.

So `UPDATE books SET last_modified = ...` fails with
`no such function: title_sort`, even for a column the trigger does not touch.

Work around it by dropping the trigger, doing the work, and putting it back
last. The `CREATE TRIGGER` must come after the final `UPDATE books`, or the
trigger fires again on the next statement and you get the same error.

```sql
BEGIN;
DROP TRIGGER books_update_trg;
UPDATE books SET last_modified = datetime('now') WHERE id = 75;
-- any other books updates here
CREATE TRIGGER books_update_trg
            AFTER UPDATE ON books
            BEGIN
            UPDATE books SET sort=title_sort(NEW.title)
                         WHERE id=NEW.id AND OLD.title <> NEW.title;
            END;
COMMIT;
```

Read the exact body back first, and copy it verbatim:

```bash
sqlite3 metadata.db "select sql from sqlite_master where name='books_update_trg';"
```

## Other traps

- `tag_browser_*` and `books_*_link` name lookups are **views**, not tables.
  `DELETE FROM tag_browser_tags` fails with `cannot modify ... because it is a
  view`. They rebuild themselves, so leave them alone.
- `data.name` is the base name **without** an extension. The real path is
  `<books.path>/<data.name>.<lowercase format>`.
- Apostrophes break generated SQL. Either double them (`O'Brien` becomes
  `O''Brien` in awk with `gsub(/\047/,"\047\047",v)`) or skip generated SQL and
  write directly against an `ATTACH`ed database.
- Bump `books.last_modified` so Calibre knows the record moved on. Keeping it
  newer than the OPF is the safe direction.

## Replacing a whole facet

Delete the links and the values, then rebuild. Never try to patch values one at
a time, or typos and near-duplicates survive.

```sql
BEGIN;
DELETE FROM books_tags_link;
DELETE FROM tags;
INSERT INTO tags(name) VALUES('Fantasy');
-- one INSERT per vocabulary word
INSERT INTO books_tags_link(book,tag) SELECT 3,id FROM tags WHERE name='Fantasy';
-- one INSERT per book and tag
COMMIT;
```

Guard the rebuild by checking the mapping file first:

```bash
comm -23 <(sqlite3 metadata.db "select id from books order by id;") \
         <(cut -f1 map.tsv | sort -n)                  # books missing from the map
cut -f1 map.tsv | sort | uniq -d                        # duplicate ids
awk -F'\t' '$3==""{print $1}' map.tsv                   # books with no shelves
```

## Renaming a book

Changing `books.title` or `books.author_sort` changes nothing on disk. Calibre
looks books up by `books.path`, so a rename leaves the old folder and filenames
in place and the library still works, just untidily.

Make the three parts agree, in this order, and update the database last:

1. Move the folder, and rename the format files inside it.
2. Drop `books_update_trg`, update `books.path`, restore the trigger.
3. Update `data.name`, which is the base name without an extension.

```sql
BEGIN;
DROP TRIGGER books_update_trg;
UPDATE books SET path='Susanna Clarke/Piranesi (109)' WHERE id=109;
CREATE TRIGGER books_update_trg
            AFTER UPDATE ON books
            BEGIN
            UPDATE books SET sort=title_sort(NEW.title)
                         WHERE id=NEW.id AND OLD.title <> NEW.title;
            END;
COMMIT;
UPDATE data SET name='Piranesi - Susanna Clarke' WHERE book=109 AND format='EPUB';
```

Then prove the file really exists at the path the database now claims, since a
failed move leaves a record pointing at nothing:

```bash
sqlite3 metadata.db "select path||'/'||name||'.epub' from books b join data d on d.book=b.id;" \
  | while read -r f; do [ -f "$f" ] || echo "MISSING $f"; done
```

Renaming also strands the old file on a synced reader. See `references/kobo.md`.

## Audits

```bash
# orphaned values
sqlite3 metadata.db "select count(*) from tags where id not in (select tag from books_tags_link);"
sqlite3 metadata.db "select count(*) from books_tags_link l where not exists(select 1 from tags t where t.id=l.tag);"

# dead identifier types
sqlite3 metadata.db "select type, count(*) from identifiers group by 1;"

# formats and the disk they take
sqlite3 metadata.db "select format, count(*) from data group by 1;"
find . -name '*.mobi' -printf '%s\n' | awk '{s+=$1} END{printf "%.1f MB\n", s/1048576}'
```

Before deleting a format, prove the book keeps a usable one:

```sql
select count(*) from data d where d.format='ORIGINAL_EPUB'
  and not exists (select 1 from data e where e.book=d.book and e.format='EPUB');
```

A non-zero answer means at least one book would be left with nothing readable.

## Finishing

```bash
sqlite3 metadata.db "pragma integrity_check;"
```

Then confirm no book lost everything:

```sql
select count(*) from books b where not exists (select 1 from books_tags_link where book=b.id);
select count(*) from books b where not exists (select 1 from books_custom_column_1_link where book=b.id);
```

Both should be zero, or you dropped a facet for a book that had nothing else.
