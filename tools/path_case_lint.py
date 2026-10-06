#!/usr/bin/env python3
"""Validate exact case for res:// resource references in a Godot project."""

from __future__ import annotations

import re
import sys
from pathlib import Path

RESOURCE_RE = re.compile(r"res://[A-Za-z0-9_./@+\-]+")
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".gdshader", ".cfg", ".json", ".md"}


def iter_text_files(project_root: Path):
    for path in project_root.rglob("*"):
        if path.is_file() and path.suffix.lower() in TEXT_SUFFIXES:
            yield path


def exact_case_exists(project_root: Path, resource_path: str) -> bool:
    relative = resource_path.removeprefix("res://")
    current = project_root
    for part in Path(relative).parts:
        try:
            names = {entry.name for entry in current.iterdir()}
        except OSError:
            return False
        if part not in names:
            return False
        current = current / part
    return current.exists()


def main() -> int:
    project_root = Path(sys.argv[1] if len(sys.argv) > 1 else "godot").resolve()
    if not (project_root / "project.godot").is_file():
        print(f"Not a Godot project: {project_root}", file=sys.stderr)
        return 2

    failures: list[tuple[Path, int, str]] = []
    for source in iter_text_files(project_root):
        try:
            lines = source.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            continue
        for line_number, line in enumerate(lines, start=1):
            for match in RESOURCE_RE.finditer(line):
                resource_path = match.group(0).rstrip(".,;:)]}'\"")
                if not exact_case_exists(project_root, resource_path):
                    failures.append((source.relative_to(project_root), line_number, resource_path))

    if failures:
        for source, line_number, resource_path in failures:
            print(f"{source}:{line_number}: invalid or case-mismatched path: {resource_path}")
        print(f"Found {len(failures)} invalid resource path reference(s).", file=sys.stderr)
        return 1

    print("Resource path case check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
