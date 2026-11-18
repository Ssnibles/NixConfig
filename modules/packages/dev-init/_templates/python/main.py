from __future__ import annotations

import argparse


def main() -> None:
    parser = argparse.ArgumentParser(description="@NAME@")
    parser.add_argument("name", nargs="?", default="@NAME@")
    args = parser.parse_args()
    print(f"Hello, {args.name}!")


if __name__ == "__main__":
    main()
