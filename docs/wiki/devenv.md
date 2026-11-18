# Developer Environments

This repository uses `devenv` for project toolchains and `dev-init` for
scaffolding new projects. The NixConfig checkout itself also has a devenv shell
for working on the repository.

## Creating a project

Run `dev-init` with a target directory and a language:

```bash
dev-init my-app -l python
cd my-app
direnv allow
devenv shell
```

`dev-init` calls `devenv init` for the common `devenv.yaml`, `.envrc`, and
`.gitignore` files, then adds the language-specific `devenv.nix`, starter source
files, and a short README. The language files are real templates under
`modules/packages/dev-init/_templates/`. It never overwrites an existing file.
Use `--force` if the target directory already has unrelated files. Use `--git`
to run `git init` in the new project. The first `devenv shell` writes
`devenv.lock`; commit that file with the project.

| Language | Flag | Starter | First command |
| :--- | :--- | :--- | :--- |
| Python | `-l python` | `pyproject.toml`, `main.py` | `run` |
| Rust | `-l rust` | `Cargo.toml`, `src/main.rs` | `run` |
| Go | `-l go` | `go.mod`, `main.go` | `run` |
| Web | `-l web` | Vite, TypeScript, pnpm | `dev` |
| C | `-l c` | `CMakeLists.txt`, `src/main.c` | `configure && build && run` |

List the supported languages with:

```bash
dev-init --list
```

Show the files without writing them:

```bash
dev-init my-app -l go --dry-run
```

## What each environment contains

- Python uses `uv` with an automatic virtual environment and `uv sync`. The
  starter includes a `pyproject.toml`, a `main.py`, and a `pytest` setup.
- Rust uses the devenv Rust toolchain with cargo, clippy, rustfmt, and
  rust-analyzer. The starter is a normal Cargo binary crate.
- Go uses the devenv Go toolchain with gopls, delve, and the usual Go tools.
- Web uses Node.js 22, pnpm, TypeScript, and Vite. `pnpm install` runs on the
  first shell entry.
- C uses CMake and Ninja, with clang-tools, ccls, gdb, and valgrind from the
  devenv C language module.

## NixConfig developer shell

Enter the repository shell with either command:

```bash
nix develop
devenv shell
```

The shell contains the Nix tooling (`nixfmt`, `statix`, `deadnix`, `nil`), Fish,
`boilerplate`, and `dev-init`. Fish is entered automatically, matching the rest
of the desktop setup.

The flake checks are separate from the developer shell. They run `nixfmt`,
`deadnix`, and `statix` through `nix flake check`. A `dev-init` check also
generates all five project types and parses the generated `devenv.nix` files.
