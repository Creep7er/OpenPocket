#!/usr/bin/env python3
"""Print a compact size and contents audit for an Android APK or AAB."""

from __future__ import annotations

import argparse
from collections import Counter
from pathlib import Path
from zipfile import ZipFile


UNWANTED_PREFIXES = (
    "dist/",
    "test_fixtures/",
    "cartridges/source/",
    "docs/",
    "sdk/",
    "tools/",
    "artifacts/",
)


def human_size(value: int) -> str:
    return f"{value / (1024 * 1024):.2f} MB" if value >= 1024 * 1024 else f"{value / 1024:.2f} KB"


def analyze(path: Path) -> int:
    if not path.is_file():
        print(f"ERROR: file not found: {path}")
        return 2

    with ZipFile(path) as archive:
        entries = [entry for entry in archive.infolist() if not entry.is_dir()]
        names = [entry.filename for entry in entries]
        total_packed = path.stat().st_size
        print(f"FILE {path}")
        print(f"SIZE {human_size(total_packed)} ({total_packed} bytes)")
        print("\nLARGEST FILES")
        print("FILE | COMPRESSED | UNCOMPRESSED | RATIO | APK")
        for entry in sorted(entries, key=lambda item: item.compress_size, reverse=True)[:20]:
            ratio = entry.compress_size / entry.file_size if entry.file_size else 0.0
            share = entry.compress_size / total_packed * 100.0 if total_packed else 0.0
            print(
                f"{entry.filename} | {human_size(entry.compress_size)} | "
                f"{human_size(entry.file_size)} | {ratio:.1%} | {share:.1f}%"
            )

        assets = [entry for entry in entries if "/assets/" in f"/{entry.filename}" or entry.filename.startswith("assets/")]
        pctrg = [name for name in names if name.lower().endswith(".pctrg")]
        abis = sorted(
            {
                parts[parts.index("lib") + 1]
                for name in names
                if "lib" in (parts := name.split("/")) and parts.index("lib") + 2 < len(parts)
            }
        )
        debug_files = [name for name in names if name.endswith((".dbg", ".sym", ".debug"))]
        unwanted = [name for name in names if name.startswith(UNWANTED_PREFIXES) or any(f"/{prefix}" in name for prefix in UNWANTED_PREFIXES)]
        duplicates = [name for name, count in Counter(names).items() if count > 1]
        plugin_marker = b"OpenPocketFilePicker"
        plugin_present = any(plugin_marker in archive.read(entry) for entry in entries if entry.filename.endswith(".dex"))

        print("\nAUDIT")
        print(f"ABIS {', '.join(abis) if abis else 'none'}")
        print(f"ASSETS {human_size(sum(entry.compress_size for entry in assets))}")
        print(f"PCTRG {len(pctrg)}: {', '.join(pctrg) if pctrg else 'none'}")
        print(f"PLUGIN OpenPocketFilePicker: {'yes' if plugin_present else 'no'}")
        print(f"DEBUG SYMBOL FILES {len(debug_files)}")
        print(f"DUPLICATE ZIP PATHS {len(duplicates)}")
        print(f"UNWANTED FILES {len(unwanted)}")
        for name in unwanted:
            print(f"  {name}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("file", type=Path)
    return analyze(parser.parse_args().file)


if __name__ == "__main__":
    raise SystemExit(main())
