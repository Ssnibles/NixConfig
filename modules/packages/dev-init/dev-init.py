#!/usr/bin/env python3
"""Create a devenv project for a supported language."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]*$")

LANGUAGES = {
    "python": "Python with uv and an automatic virtual environment",
    "rust": "Rust with cargo, clippy, rustfmt, and rust-analyzer",
    "go": "Go with gopls, delve, and the usual Go tools",
    "web": "Vite, TypeScript, and pnpm",
    "c": "C with CMake, Ninja, clang-tools, and gdb",
}


def template_root() -> Path:
    override = os.environ.get("DEV_INIT_TEMPLATES")
    if override:
        return Path(override)
    installed = Path(__file__).resolve().parent.parent / "share/dev-init/templates"
    if installed.is_dir():
        return installed
    return Path(__file__).resolve().parent / "_templates"


def slugify(name: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "app"


def render(text: str, name: str, package: str) -> str:
    return text.replace("@NAME@", name).replace("@PACKAGE@", package)


def language_files(language: str) -> dict[Path, str]:
    root = template_root() / language
    return {
        path.relative_to(root): path.read_text(encoding="utf-8")
        for path in sorted(root.rglob("*"))
        if path.is_file()
    }


def planned_paths(language: str) -> set[Path]:
    paths = {Path(".envrc"), Path(".gitignore"), Path("devenv.nix"), Path("devenv.yaml")}
    paths.update(
        Path(".gitignore") if path.name == "gitignore" else path
        for path in language_files(language)
    )
    return paths


def run_devenv_init(target: Path) -> None:
    if shutil.which("devenv") is None:
        raise RuntimeError("devenv was not found in PATH")
    result = subprocess.run(
        ["devenv", "init", "--include-envrc"],
        cwd=target,
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "unknown error"
        raise RuntimeError(f"devenv init failed: {message}")


def write_project(target: Path, language: str, name: str) -> None:
    package = slugify(name)
    run_devenv_init(target)

    for relative, content in language_files(language).items():
        path = target / relative
        if relative.name == "gitignore":
            with (target / ".gitignore").open("a", encoding="utf-8") as handle:
                handle.write("\n" + render(content, name, package).rstrip() + "\n")
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(render(content, name, package).rstrip() + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Create a devenv project for Python, Rust, Go, web, or C.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("path", nargs="?", help="Project directory (use . for the current directory)")
    parser.add_argument(
        "-l",
        "--language",
        choices=sorted(LANGUAGES),
        help="Project language",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List the supported languages",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Allow a non-empty target directory. Existing files are never overwritten.",
    )
    parser.add_argument(
        "--git",
        action="store_true",
        help="Run git init in the new project",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the files that would be created",
    )
    args = parser.parse_args()

    if args.list:
        print("Supported languages:")
        for language, description in LANGUAGES.items():
            print(f"  {language:<8} {description}")
        raise SystemExit(0)

    if not args.path or not args.language:
        parser.print_help()
        print("\nError: a path and --language are required.", file=sys.stderr)
        raise SystemExit(2)

    return args


def main() -> int:
    args = parse_args()
    target = Path(args.path).expanduser().resolve()
    name = target.name

    if not NAME_RE.fullmatch(name):
        print(f"Error: invalid project name '{name}'.", file=sys.stderr)
        return 2

    if target.exists():
        if not target.is_dir():
            print(f"Error: {target} is not a directory.", file=sys.stderr)
            return 2
        existing = [entry for entry in target.iterdir() if entry.name != ".git"]
        if existing and not args.force:
            print(
                f"Error: {target} is not empty. Use --force to add files anyway.",
                file=sys.stderr,
            )
            return 2
    else:
        target.mkdir(parents=True)

    planned = planned_paths(args.language)
    for relative in planned:
        if (target / relative).exists():
            print(f"Error: refusing to overwrite {target / relative}.", file=sys.stderr)
            return 2

    if args.dry_run:
        print(f"Dry run: {args.language} project in {target}")
        for relative in sorted(planned):
            print(f"  {target / relative}")
        return 0

    try:
        write_project(target, args.language, name)
    except RuntimeError as err:
        print(f"Error: {err}", file=sys.stderr)
        return 2

    if args.git:
        if shutil.which("git") is None:
            print("Error: git was not found.", file=sys.stderr)
            return 2
        subprocess.run(["git", "init", "--quiet"], cwd=target, check=True)

    print(f"Created {args.language} project in {target}")
    print()
    print("Next:")
    if target != Path.cwd():
        print(f"  cd {target}")
    print("  direnv allow")
    print("  devenv shell")
    print(f"  # then run: {run_command(args.language)}")

    return 0


def run_command(language: str) -> str:
    return {
        "python": "run",
        "rust": "run",
        "go": "run",
        "web": "dev",
        "c": "configure && build && run",
    }[language]


if __name__ == "__main__":
    raise SystemExit(main())
