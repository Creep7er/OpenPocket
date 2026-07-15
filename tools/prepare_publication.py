#!/usr/bin/env python3
"""Create a clean source snapshot from the current tracked worktree."""

from __future__ import annotations

import argparse
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DESTINATION = ROOT / "publication" / "openpocket-0.3.2"
EXCLUDED_PREFIXES = (
    ".git/",
    ".godot/",
    ".tools/",
    ".tmp/",
    ".cache/",
    "artifacts/",
    "build/",
    "dist/",
    "exports/",
    "publication/",
)
EXCLUDED_SUFFIXES = (".apk", ".aab", ".jks", ".keystore", ".pyc")


def tracked_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "-z"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    return [Path(item.decode("utf-8")) for item in result.stdout.split(b"\0") if item]


def included(relative: Path) -> bool:
    normalized = relative.as_posix()
    return not normalized.startswith(EXCLUDED_PREFIXES) and not normalized.lower().endswith(EXCLUDED_SUFFIXES)


def write_notes(destination: Path, count: int) -> None:
    notes = destination.parent / ".publication-notes.md"
    notes.write_text(
        f"""# OpenPocket 0.3.2 publication notes

Copy the {count} files inside `openpocket-0.3.2/` into a new empty directory.
Do not copy this notes file, the private `.git` directory, APK/AAB files, exports,
local tools, user data, logs, or Android signing material.

Suggested repository: `Creep7er/OpenPocket`

Suggested description:

> An open-source pixel-art virtual handheld for Android with installable cartridge apps and games.

Suggested topics: `godot`, `android`, `pixel-art`, `retro-gaming`, `open-source`,
`game-console`, `cartridge`, `gdscript`.

Recommended initial commit: `feat: publish OpenPocket 0.3.2`

After publication:

1. Enable Issues and Discussions if they will be maintained.
2. Enable private vulnerability reporting before accepting security reports.
3. Create release `0.3.2` and attach the compact APK and AAB separately.
4. Confirm the public clone passes the documented validation and Godot import.
""",
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", nargs="?", default=str(DEFAULT_DESTINATION))
    args = parser.parse_args()
    destination = Path(args.destination).resolve()
    publication_root = (ROOT / "publication").resolve()
    if destination != publication_root and publication_root not in destination.parents:
        raise SystemExit("Destination must stay inside publication/")
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    (destination.parent / ".gdignore").touch()

    copied = 0
    for relative in tracked_files():
        source = ROOT / relative
        if not source.is_file() or not included(relative):
            continue
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        copied += 1

    write_notes(destination, copied)
    size = sum(path.stat().st_size for path in destination.rglob("*") if path.is_file())
    print(f"Publication snapshot: {destination}")
    print(f"Files: {copied}")
    print(f"Bytes: {size}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
