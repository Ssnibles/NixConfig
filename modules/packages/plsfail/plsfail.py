#!/usr/bin/env python3

from __future__ import annotations

import argparse
import subprocess
import sys
import shlex


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a command until it fails")
    parser.add_argument(
        "-n",
        "--tries",
        type=int,
        default=0,
        help="Maximum number of attempts; 0 means keep going until failure",
    )
    parser.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="Increase progress output",
    )
    parser.add_argument(
        "-q",
        "--quiet",
        action="count",
        default=0,
        help="Reduce extra progress output",
    )
    parser.add_argument(
        "command",
        nargs=argparse.REMAINDER,
        help="Command to run, prefixed by -- if it has its own flags",
    )
    return parser.parse_args()


def progress_level(verbose: int, quiet: int) -> int:
    return max(verbose - quiet, 0)


def print_progress(level: int, message: str, *, minimum_level: int = 0) -> None:
    if level >= minimum_level:
        print(message, file=sys.stderr, flush=True)


def main() -> int:
    args = parse_args()

    command = list(args.command)
    if command[:1] == ["--"]:
        command = command[1:]
    if not command:
        print("usage: plsfail [options] -- command [args...]", file=sys.stderr)
        return 2

    level = progress_level(args.verbose, args.quiet)
    tries = args.tries
    attempt = 0

    while True:
        attempt += 1
        print_progress(level, f"try {attempt}: running {shlex.join(command)}")
        result = subprocess.run(command, capture_output=True, text=True)

        if result.returncode != 0:
            print_progress(level, f"try {attempt}: failed with exit code {result.returncode}")
            if result.stdout:
                sys.stdout.write(result.stdout)
                sys.stdout.flush()
            if result.stderr:
                sys.stderr.write(result.stderr)
                sys.stderr.flush()
            return result.returncode

        print_progress(level, f"try {attempt}: ok")

        if tries > 0 and attempt >= tries:
            print_progress(level, f"completed {attempt} tries without failure")
            return 0


if __name__ == "__main__":
    raise SystemExit(main())
