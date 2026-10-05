# Pi skills

Bundled skills that teach the pi coding agent this user's document and study
conventions. Each skill is a directory with a `SKILL.md` (frontmatter `name:` must
match the directory name, plus a `description:` that drives when pi loads it) and,
where useful, a `references/` folder of examples.

The `description:` is the trigger. Write it so the skill loads for the right task
and stays out of the way otherwise.

## The suite

| Skill | Loads when | Depends on |
|---|---|---|
| [`typst-snippets`](typst-snippets/SKILL.md) | Writing or editing any `.typ` file | — |
| [`lecture-notes`](lecture-notes/SKILL.md) | Turning slides, recordings or readings into study notes | `typst-snippets` |
| [`test-notes`](test-notes/SKILL.md) | Working through a past test, exam or practice paper | `typst-snippets` |
| [`lab-notes`](lab-notes/SKILL.md) | Recording a lab, practical or exercise | `typst-snippets` |
| [`assignment-report`](assignment-report/SKILL.md) | Answering a brief in an assignment, report or design doc | `typst-snippets` |
| [`revision-sheets`](revision-sheets/SKILL.md) | Making a cram sheet or active-recall question bank | `typst-snippets` |

`typst-snippets` is the foundation: it defines the shared theme, the helper
functions (`#callout`, `#card`, `#qa`, `#uml-class`, …), the palette, and the
"how it should look" rules. The other skills define *what* a document should
contain and all tell pi to load `typst-snippets` as well.

## Shared conventions

Across every notes skill:

- **Read the source first.** Extract text with `pdftotext`, then render the pages
  to images and read the ones carrying diagrams/code (text extraction drops them).
- **Explain, don't re-type.** Notes are a learning instrument, not a copy of the
  source. Compress, connect, and add a self-test.
- **Use the helpers**, never hand-rolled blocks. All styling comes from
  `templates/theme.typ`.
- **Leave intentionally standalone notes alone.** A few existing lab/test notes
  carry their own preamble (different background, custom title block) on purpose.
- **Compile before finishing**: `typst compile --root <repo> "<note>.typ"`, and
  fix any warnings (notably `**`, which is a Markdown-ism that Typst warns about).

## Adding a skill

1. Create `skills/<name>/SKILL.md` with `name: <name>` frontmatter matching the
   directory and a trigger-focused `description`.
2. Add any reference files under `skills/<name>/references/`.
3. Wire it into `../pi-agent.nix`:
   - add a `features.pi-agent.<name>` bool option (default `true`), and
   - add `lib.optional cfg.<name> (mkSkill "<name>" ./pi-agent/skills/<name>)` to
     `bundledSkills`.
4. **Make sure git tracks the new files.** Nix flakes only see files in the git
   index, so `git add` the directory (or commit with `jj`) or the store copy will
   silently omit it.
5. If the skill has a `references/example.typ`, make it import the shared theme so
   the build guard compiles it (see below).
6. Keep the `README.md` table above up to date.

## Build guard

`check-skills.sh` runs at build time on every skill. It checks that `SKILL.md` has
a `name:` matching its directory and a non-empty `description:`, then compiles
any `references/*.typ` that imports the shared theme. A broken example or a
mislabelled skill fails the Nix build.

The examples import `cetz`/`zap`/`mmdr` (through the theme), so `pi-agent.nix`
vendors those Typst packages as `typstPreviewPackages` and passes
`--package-path`/`--font-path` to the compiler, keeping the guard offline and
reproducible. Run it by hand with:

```bash
bash check-skills.sh <skill-dir> --expect <name> \
  --compile --theme path/to/theme.typ --package-path <pkgs> --font-path <fonts>
```

## Bundling

`modules/features/apps/pi-agent.nix` installs `typst-snippets` with a dedicated
`runCommand` (it copies the theme, the `page` snippet and the reference files,
then runs `check-sync.sh` and `check-skills.sh`). Every other skill goes through
the generic `mkSkill` helper, which copies it and runs the build guard. New
skills get an option (`features.pi-agent.<name>`, default `true`) and an entry in
`bundledSkills`.
