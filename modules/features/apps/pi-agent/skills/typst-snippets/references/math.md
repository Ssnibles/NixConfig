# Math reference

Typst math uses **Typst names, never LaTeX**. Inline math is `$...$`; display math
is `$ ... $` on its own line. The snippets below are what the editor inserts —
mirror the expansion, not a LaTeX equivalent.

## Delimiters, structure, and brackets

| Trigger | Expands to |
|---|---|
| `$` | inline `$…$` |
| `$$` | display `$ … $` |
| `eq` | multi-line equation block |
| `eqalign` | aligned block, `&=` on each line |
| `lr` / `lrb` / `lrc` | `lr(…)` / `lr([…])` / `lr({…})` |
| `abs` / `norm` | `|…|` / `||…||` |
| `ceil` / `floor` / `cases` | `ceil(…)` / `floor(…)` / `cases(…)` |
| `set` / `setb` | `{ … }` / `{ x in S : P(x) }` |

## Operators and functions

| Trigger | Expands to |
|---|---|
| `frac` | `(num)/(den)` |
| `sum` | `sum_(i=0)^(n)` |
| `prod` | `prod_(i=0)^(n)` |
| `int` | `integral_(a)^(b)` |
| `lim` | `lim_(x -> inf)` |
| `sqrt` / `root` | `sqrt(x)` / `root(n, x)` |
| `pdiff` / `diff` | `(diff f)/(diff x)` / `(d f)/(d x)` |
| `binom` | `binom(n, k)` |

## Matrices, vectors, and accents

| Trigger | Expands to |
|---|---|
| `vec` / `mat` / `mat2` / `mat3` | `vec(…)` / `mat(…)` / 2×2 / 3×3 |
| `det` / `trace` | `det …` / `tr …` |
| `transpose` / `inv` | `…^T` / `…^(-1)` |
| `conj` | `conj(…)` |
| `hat` / `bar` / `tilde` | `hat(…)` / `overline(…)` / `tilde(…)` |
| `dot` / `ddot` | `dot(…)` / `dot.double(…)` |

## Relations, sets, and symbols

| Trigger | Expands to |
|---|---|
| `inff` / `nab` | `infinity` / `nabla` |
| `arr` / `rarr` / `larr` / `uarr` / `darr` | `arrow` / `arrow.r` / `arrow.l` / `arrow.t` / `arrow.b` |
| `iff` / `==>` | `<==>` / `==>` |
| `therefore` / `because` / `forall` / `exists` | `therefore` / `because` / `forall` / `exists` |
| `elem` / `notin` / `subs` | `in` / `in.not` / `subset` |
| `cup` / `cap` / `empty` | `union` / `intersection` / `nothing` |
| `neq` / `leq` / `geq` / `approx` | `!=` / `<=` / `>=` / `approx` |
| `times` / `cdot` | `times` / `dot.c` |

## Number sets

| Trigger | Expands to |
|---|---|
| `RR` (alias `add`) | `RR` |
| `NN` / `ZZ` / `QQ` / `CC` | `NN` / `ZZ` / `QQ` / `CC` |

## Greek letters

| Trigger | `aa` | `bb` | `gg` | `dd` | `ee` | `th` | `ll` | `mm` |
|---|---|---|---|---|---|---|---|---|
| Letter | `alpha` | `beta` | `gamma` | `delta` | `epsilon` | `theta` | `lambda` | `mu` |

| Trigger | `pp` | `ss` | `oo` | `ph` | `ps` | `rh` | `ta` |
|---|---|---|---|---|---|---|---|
| Letter | `pi` | `sigma` | `omega` | `phi` | `psi` | `rho` | `tau` |

## Rules

- Define each symbol on first use.
- Keep display equations on their own line; do not bury them in a paragraph.
- Use the `eq` / `eqalign` snippets for multi-line derivations, aligned on `&=`.
