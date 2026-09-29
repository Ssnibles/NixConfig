# Math reference

Typst math uses **Typst names, never LaTeX**. Inline math is `$...$`; display math
is `$ ... $` on its own line. The snippets below are what the editor inserts —
mirror the expansion, not a LaTeX equivalent.

## Delimiters, structure, and brackets

| Trigger | Expands to |
|---|---|
| `$` | inline `$…$` |
| `$$` | display `$ … $` |
| `equation` | multi-line equation block |
| `equation-align` | aligned block, `&=` on each line |
| `delimiters` / `delimiters-bracket` / `delimiters-curly` | `lr(…)` / `lr([…])` / `lr({…})` |
| `abs` / `norm` | `|…|` / `||…||` |
| `ceil` / `floor` / `cases` | `ceil(…)` / `floor(…)` / `cases(…)` |
| `set` / `set-builder` | `{ … }` / `{ x in S : P(x) }` |

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
| `infinity` / `nabla` | `infinity` / `nabla` |
| `arrow` / `arrow-right` / `arrow-left` / `arrow-up` / `arrow-down` | `arrow` / `arrow.r` / `arrow.l` / `arrow.t` / `arrow.b` |
| `iff` / `==>` | `<==>` / `==>` |
| `therefore` / `because` / `forall` / `exists` | `therefore` / `because` / `forall` / `exists` |
| `elem` / `notin` / `subset` | `in` / `in.not` / `subset` |
| `supset` / `subset-equal` / `superset-equal` | `supset` / `subset.eq` / `supset.eq` |
| `cup` / `cap` / `empty` | `union` / `intersection` / `nothing` |
| `neq` / `leq` / `geq` / `approx` | `!=` / `<=` / `>=` / `approx` |
| `times` / `cdot` | `times` / `dot.c` |

## Number sets

| Trigger | Expands to |
|---|---|
| `real` | `real` |
| `natural` / `integer` / `rational` / `complex` | `natural` / `integer` / `rational` / `complex` |

## Greek letters

| Trigger | `alpha` | `beta` | `gamma` | `delta` | `epsilon` | `theta` | `lambda` | `mu` |
|---|---|---|---|---|---|---|---|---|
| Letter | `alpha` | `beta` | `gamma` | `delta` | `epsilon` | `theta` | `lambda` | `mu` |

| Trigger | `pi` | `sigma` | `omega` | `phi` | `psi` | `rho` | `tau` |
|---|---|---|---|---|---|---|---|
| Letter | `pi` | `sigma` | `omega` | `phi` | `psi` | `rho` | `tau` |

| Trigger | `zeta` | `eta` | `iota` | `kappa` | `nu` | `xi` | `chi` | `upsilon` | `omicron` |
|---|---|---|---|---|---|---|---|---|---|
| Letter | `zeta` | `eta` | `iota` | `kappa` | `nu` | `xi` | `chi` | `upsilon` | `omicron` |

## Rules

- Define each symbol on first use.
- Keep display equations on their own line; do not bury them in a paragraph.
- Use the `equation` / `equation-align` snippets for multi-line derivations, aligned on `&=`.
