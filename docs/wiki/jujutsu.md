# Jujutsu (jj) Cheat Sheet

Quick reference for `jj` — the Git-compatible VCS used in this repo. Jujutsu works **on top of your Git repo** (the `.git/` directory stays), so all your remotes, history, and CI stay intact.

---

## 🧠 Key Mental Model Differences from Git

| Git concept | jj equivalent | Notes |
|---|---|---|
| Branch | **Bookmark** | `jj bookmark` — just a movable label on a commit |
| `HEAD` | **Working copy (`@`)** | Always a real commit that auto-updates as you edit files |
| Staging / `git add` | *None* | Every file change is **automatically recorded** into `@` |
| `git commit` | `jj commit` / `jj new` | `jj commit` = describe `@` and create a new empty child; `jj new` = just create a new child |
| `git stash` | *Not needed* | Just `jj new` to start fresh — your old work stays as a commit |
| `git rebase -i` | `jj rebase` / `jj squash` | Much simpler — no interactive editor needed |

> [!IMPORTANT]
> There is **no staging area**. Every save you make is instantly part of the working-copy commit `@`. To split changes out, use `jj split`.

---

## 📋 Daily Workflow

### Seeing what's going on

```bash
jj status          # (alias: js) — what files changed in @
jj log             # (alias: jl) — commit graph
jj diff            # (alias: jd) — diff of current changes in @
jj log -r 'all()'  # show the entire commit graph
```

### Making commits

```bash
# You've been editing files — they're already in @.
jj commit -m "feat: add new module"    # (alias: jc) — describe @ and start a new empty @ on top
jj describe -m "fix: typo"            # change the description of @ without creating a new commit
```

> [!NOTE]
> **Understanding `@` vs `@-`**:
> In Git, after `git commit`, `HEAD` points to the commit you just made.
> In `jj`, after `jj commit`, `@` is a *new empty child commit* (your clean workspace), and your newly committed work is now at `@-` (the parent of `@`).

### Committing specific files (partial commits)

Unlike Git where you `git add <files>` first, in `jj` you can commit specific files or directories directly from `@`:

```bash
jj commit <path/to/file_or_dir> -m "feat: description"
```
The selected files are committed into the new commit, and all other modified files stay in your working copy (`@`) untouched.

You can also commit specific hunks interactively (like `git add -p`):
```bash
jj commit -i -m "feat: description"
```

### Starting new work

```bash
jj new              # (alias: jn) — create a new empty commit on top of @
jj new -m "wip: experimenting"         # new commit with a message
jj new main         # new commit branching off of bookmark "main"
```

### Editing an older commit

```bash
jj edit <change-id>   # (alias: je) — jump @ to that commit so edits go there
jj new <change-id>    # create a new child of that commit instead
```

> [!TIP]
> Change IDs (the short random-letter IDs like `kxryzmsp`) are **stable** — they never change even when you rebase. Commit hashes change; change IDs don't. Prefer them.

---

## 🔖 Bookmarks (Branches)

jj calls branches **bookmarks** — they're just labels pointing at commits.

### Creating & moving bookmarks

```bash
jj bookmark create my-feature         # create bookmark pointing at @
jj bookmark create my-feature -r <rev> # create bookmark pointing at a specific revision
jj bookmark set my-feature            # move existing bookmark to @
jj bookmark set my-feature -r <rev>   # move bookmark to a specific revision
jj bookmark list                      # (alias: jb list) — list all bookmarks
```

### Deleting bookmarks

```bash
jj bookmark delete my-feature         # delete local bookmark
jj git push --bookmark my-feature --deleted  # push the deletion to the remote
```

### Tracking remote bookmarks

```bash
jj bookmark track main --remote origin          # track remote bookmark locally
jj bookmark track my-feature --remote origin    # track a feature branch from origin
jj git fetch                                    # (alias: jf) — fetch all remote changes
```

> [!TIP]
> **Fixing "Non-tracking remote bookmark exists"**:
> If pushing fails with `Error: Non-tracking remote bookmark <name>@origin exists`, tell jj to track it:
> ```bash
> jj bookmark track <name> --remote origin
> ```

---

## 🚀 Pushing & Pulling

### Pushing to a remote

```bash
jj git push                            # (alias: jp) — push all locally-changed bookmarks
jj git push --bookmark my-feature      # push only a specific bookmark
jj git push --all                      # push all bookmarks
jj git push --change @                 # auto-create a bookmark from @'s change-id and push it
```

> [!TIP]
> `jj git push --change @` is great for quick PRs — it auto-names the bookmark `push-<change-id>` so you don't have to create one manually.

### Pulling from a remote

```bash
jj git fetch                           # (alias: jf) — fetch from all remotes
jj git fetch --remote origin           # fetch from a specific remote
jj rebase -d main                      # rebase your current work onto updated main
```

### Typical "pull & rebase" flow

```bash
jj git fetch                           # get latest
jj rebase -d main                      # put your work on top of main
jj git push --bookmark my-feature      # push your updated bookmark
```

### Pushing straight to main (solo repos)

For solo repos like NixConfig where you're the only contributor, you can push directly to `main`:

```bash
# Case 1: You just ran `jj commit` (your commit is at @-):
jj bookmark set main -r @-            # advance "main" bookmark to your commit
jj git push --bookmark main           # push it (alias: jp --bookmark main)

# Case 2: You only described @ (jj describe) and want to push @:
jj bookmark set main -r @             # move "main" to point at your working copy
jj git push --bookmark main           # push it
```

> [!WARNING]
> This is a **force-push** if remote `main` has diverged. To stay safe, fetch and rebase first:

### Safe push-to-main flow

```bash
jj git fetch                           # (alias: jf) — get latest remote changes
jj rebase -d main                      # rebase your work onto latest main
jj bookmark set main -r @-             # advance main to your commit (@- if committed, @ if working copy)
jj git push --bookmark main           # (alias: jp --bookmark main) — push
```

---

## ✂️ Rewriting History

### Squash (consolidating commits & changes)

```bash
# Basic squashing
jj squash                              # squash @ into its parent (@-)
jj squash -r <rev>                     # squash a specific commit into its parent
jj squash --into <rev>                 # squash @ into a specific target commit
jj squash --from <src> --into <dst>    # squash commit <src> into commit <dst>

# Squashing specific files or directories (partial squash)
jj squash <path>                       # move only <path> from @ into @-
jj squash --from <src> --into <dst> <path>  # move only <path> from <src> into <dst>

# Squashing a range of commits (e.g. combining 3 commits into 1)
jj squash --from <rev2>::<rev3> --into <rev1>

# Interactive squashing (choose diff hunks visually)
jj squash -i                           # interactively choose what to squash from @ into @-
jj squash -i --from <src> --into <dst> # interactively move hunks between commits

# Squash with a new description directly
jj squash -m "feat: new message"       # squash @ into @- and update description
```

### Split a commit

```bash
jj split                               # interactively split @ into two commits
jj split -r <rev>                      # split a different commit
```

### Rebase

```bash
jj rebase -r <rev> -d <destination>    # rebase a single commit
jj rebase -s <rev> -d <destination>    # rebase a commit and all its descendants
jj rebase -b <rev> -d <destination>    # rebase a whole branch (all ancestors up to a fork point)
```

### Abandon (delete) a commit

```bash
jj abandon                             # abandon @ (like deleting a commit)
jj abandon <rev>                       # abandon a specific commit
```

---

## 💥 Conflict Resolution

jj handles conflicts **as first-class data** — you can rebase on top of conflicts and resolve them later.

```bash
jj status                              # shows conflicted files
jj resolve                             # open the merge tool for conflicted files
jj resolve <file>                      # resolve a specific file
```

Alternatively, just edit the conflict markers in the file directly (they look like Git's `<<<<<<<` markers) and save — jj will detect the resolution automatically.

> [!NOTE]
> Unlike Git, jj lets you **keep working on top of conflicts** — they won't block you. Resolve them whenever you're ready.

---

## 🔧 Useful Extras

### Undo anything

```bash
jj undo                                # undo the last jj operation
jj op log                              # view operation history (every jj command is logged)
jj op restore <op-id>                  # jump back to any point in operation history
```

### Show a commit's details

```bash
jj show                                # show @ in detail (diff + description)
jj show <rev>                          # show a specific commit
```

### Duplicate a commit

```bash
jj duplicate <rev>                     # create a copy of a commit
```

### Interop with Git

```bash
jj git import                          # import Git refs/branches you created outside jj
jj git export                          # export jj bookmarks back to Git refs
```

### Allowing large files (e.g. screenshots)

By default, `jj` refuses to snapshot new untracked files larger than 1.0 MiB to prevent accidental repository bloat. To allow larger files:

```bash
jj config set --repo snapshot.max-new-file-size 2M    # increase repo limit (e.g. 2M or bytes)
```

---

## ⌨️ Your Shell Aliases

These aliases are configured in [`shell.nix`](../../modules/features/shell/shell.nix):

| Alias | Command | Description |
|---|---|---|
| `j` | `jj` | Shorthand |
| `jl` | `jj log` | View commit graph |
| `jd` | `jj diff` | Diff working copy |
| `js` | `jj status` | Working copy status |
| `jc` | `jj commit` | Commit and start new change |
| `jn` | `jj new` | Start a new empty change |
| `je` | `jj edit` | Jump to a commit to edit it |
| `jb` | `jj bookmark` | Bookmark management |
| `jp` | `jj git push` | Push to remote |
| `jf` | `jj git fetch` | Fetch from remote |

You also have **jjui** available via `Prefix + g` in tmux for a TUI interface.

---

## 📖 Further Reading

- [Jujutsu Official Docs](https://jj-vcs.github.io/jj/latest/)
- [Steve's jj Tutorial](https://steveklabnik.github.io/jujutsu-tutorial/)
- `jj help <command>` — built-in help for any command
