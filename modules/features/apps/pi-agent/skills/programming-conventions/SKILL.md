---
name: programming-conventions
description: Conventions for any programming task, including writing, editing, refactoring, reviewing, debugging, or configuring code. Load this for all code work, together with the base-conventions skill.
---

# Programming conventions

Load `base-conventions` as well. It defines British English and the general writing rules.

## Before changing code

- Read the relevant files first.
- Find the existing pattern and follow it.
- Make the smallest change that solves the problem.
- Do not change unrelated code.
- Check what the build, tests, or formatter expect.

## Comments in code

- Comment only when the code cannot explain itself.
- Explain why, not what. The code already shows what it does.
- Keep a comment to one to three short lines.
- Use plain text and normal punctuation.
- Do not use decorative separators, arrows, or special symbols.
- Do not comment out code. Delete it; version control keeps the history.
- Do not add a comment that only restates the next line.
- Do not add section labels for obvious groups.
- Keep comments that record a bug, a workaround, an upstream limit, or a non obvious choice.
- Remove stale comments as part of the change.
- Write comments in British English.

## Code

- Use clear names.
- Keep functions and modules focused.
- Prefer simple code over clever code.
- Handle errors where they happen.
- Do not hide failures or leave empty catch blocks.
- Do not add dependencies without a reason.
- Keep formatting consistent with the surrounding code.
- Do not rename public APIs or third party identifiers to British spellings. Prose changes, code stays compatible.

## Verification

- Run the relevant check, test, build, or formatter after the change.
- If you cannot run it, say so and explain what remains unverified.
- Check the diff for accidental changes.
- Report what changed and why, in plain British English.
