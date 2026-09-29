#!/usr/bin/env bash
# Drift guard for the typst-snippets skill.
#
# The shared theme (`templates/theme.typ`, bundled here as
# `references/theme.typ`) is the single source of truth for the styling. The
# `page` snippet only imports it, and `references/page-preamble.typ` mirrors that
# import. Fail the build if any of those drift apart.
#
#   bash check-sync.sh <dir-containing-typst.lua-page-preamble.typ-theme.typ>
set -euo pipefail
dir="${1:-$(cd "$(dirname "$0")" && pwd)/references}"
lua="$dir/typst.lua"
typ="$dir/page-preamble.typ"
theme="$dir/theme.typ"

fail() { echo "typst-snippet drift: $1" >&2; exit 1; }

[ -f "$lua" ] || fail "missing $lua"
[ -f "$typ" ] || fail "missing $typ"
[ -f "$theme" ] || fail "missing $theme"

# 1. the theme defines everything notes rely on.
for binding in "theme(" "note-title(" "callout(" "card(" "qa(" "uml-class(" \
  "proof(" "bigo(" "code-line-numbers" "lang-meta" "font-sans" "font-serif" \
  "font-mono" "mmdr-theme" "zap-theme"; do
  grep -q "#let $binding" "$theme" || fail "theme.typ does not define #let $binding"
done

# 2. the `page` snippet imports the theme rather than inlining it.
grep -q '#import "/templates/theme.typ": \*' "$lua" || fail "page snippet does not import the theme"
grep -q '#show: theme.with(course:' "$lua" || fail "page snippet does not apply the theme"

# 3. the reference preamble mirrors the streamlined header.
grep -q '#import "/templates/theme.typ": \*' "$typ" || fail "page-preamble.typ does not import the theme"
grep -q '#show: theme.with(course:' "$typ" || fail "page-preamble.typ does not apply the theme"
grep -q '#note-title(date,' "$typ" || fail "page-preamble.typ does not use #note-title"

echo "typst-snippets: theme, page snippet and reference preamble agree"
