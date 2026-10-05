#!/usr/bin/env bash
# Validate a bundled pi skill.
#
#   check-skills.sh <skill-dir> [--expect <name>]
#       Check the SKILL.md frontmatter: a non-empty `name:` (equal to --expect,
#       or to the directory name by default) and a non-empty `description:`.
#
#   check-skills.sh <skill-dir> [--expect <name>] --compile \
#       --theme <theme.typ> [--package-path <dir>] [--font-path <dir>]
#       Additionally compile every references/*.typ that imports the shared
#       theme, so examples cannot silently drift. The package path and font
#       path let this run without network access.
#
# Exits non-zero on the first problem.
set -euo pipefail

usage() {
  sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
}

skill=""
expect=""
compile=0
theme=""
pkgpath=""
fontpath=""

while [ $# -gt 0 ]; do
  case "$1" in
    --expect) expect="${2:?--expect needs a name}"; shift 2 ;;
    --compile) compile=1; shift ;;
    --theme) theme="${2:?--theme needs a path}"; shift 2 ;;
    --package-path) pkgpath="${2:?--package-path needs a directory}"; shift 2 ;;
    --font-path) fontpath="${2:?--font-path needs a directory}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "check-skills: unknown option: $1" >&2; exit 1 ;;
    *) [ -z "$skill" ] || { echo "check-skills: unexpected argument: $1" >&2; exit 1; }; skill="$1"; shift ;;
  esac
done

fail() { echo "check-skills: $*" >&2; exit 1; }

[ -n "$skill" ] || fail "usage: check-skills.sh <skill-dir> [--expect <name>] [--compile --theme <theme.typ> ...]"
[ -d "$skill" ] || fail "$skill is not a directory"
[ -f "$skill/SKILL.md" ] || fail "$skill/SKILL.md is missing"
[ -n "$expect" ] || expect=$(basename "$skill")

frontmatter=$(sed -n '2,/^---$/p' "$skill/SKILL.md")
name=$(printf '%s\n' "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -1)
desc=$(printf '%s\n' "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -1)

[ -n "$name" ] || fail "$expect/SKILL.md has no 'name:' in its frontmatter"
[ "$name" = "$expect" ] || fail "$expect/SKILL.md declares name '$name', expected '$expect'"
[ -n "$desc" ] || fail "$expect/SKILL.md has an empty 'description:'"
echo "check-skills: $expect frontmatter OK"

[ "$compile" -eq 1 ] || exit 0
[ -n "$theme" ] || fail "--compile requires --theme <theme.typ>"
[ -f "$theme" ] || fail "theme not found: $theme"
command -v typst >/dev/null 2>&1 || fail "typst is not on PATH (needed for --compile)"

# Compile out-of-tree so the package/theme imports resolve under a stable root.
root=$(mktemp -d)
mkdir -p "$root/templates"
cp "$theme" "$root/templates/theme.typ"

shopt -s nullglob
examples=("$skill"/references/*.typ)
shopt -u nullglob

compiled=0
for ex in "${examples[@]}"; do
  if ! grep -q '#import "/templates/theme.typ"' "$ex"; then
    echo "check-skills: skip $(basename "$ex") (fragment, no theme import)"
    continue
  fi
  cp "$ex" "$root/example.typ"
  args=(compile --root "$root")
  [ -n "$pkgpath" ] && args+=(--package-path "$pkgpath")
  [ -n "$fontpath" ] && args+=(--font-path "$fontpath")
  if ! typst "${args[@]}" "$root/example.typ" "$root/out.pdf"; then
    fail "failed to compile $(basename "$ex")"
  fi
  echo "check-skills: compiled $(basename "$ex")"
  compiled=$((compiled + 1))
done

if [ "$compiled" -eq 0 ]; then
  echo "check-skills: $expect has no compilable reference examples"
fi
