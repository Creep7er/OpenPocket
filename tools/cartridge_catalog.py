#!/usr/bin/env python3
"""Generate a local mock store catalog from built .pctrg files."""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
import zipfile
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read_manifest(path: Path) -> dict:
    with zipfile.ZipFile(path, "r") as archive:
        return json.loads(archive.read("cartridge.json").decode("utf-8"))


def build_catalog(source: Path, output: Path) -> None:
    entries: list[dict] = []
    for path in sorted(source.glob("*.pctrg")):
        manifest = read_manifest(path)
        author = manifest.get("author", {})
        author_name = author.get("name", "Unknown") if isinstance(author, dict) else str(author)
        store = manifest.get("store", {}) if isinstance(manifest.get("store", {}), dict) else {}
        entries.append(
            {
                "id": manifest["id"],
                "name": manifest["name"],
                "version": manifest["version"],
                "type": manifest["type"],
                "category": manifest.get("category", "misc"),
                "author": author_name,
                "description": manifest.get("description", ""),
                "icon": "icons/" + manifest["id"] + ".png",
                "download": "mock_packages/" + path.name,
                "size": path.stat().st_size,
                "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                "featured": bool(store.get("featured", False)),
                "tags": list(store.get("tags", [])),
                "curated": True,
            }
        )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(
            {
                "schema_version": 2,
                "generated_at": datetime.now(timezone.utc).replace(microsecond=0).isoformat(),
                "cartridges": entries,
            },
            indent=2,
            sort_keys=True,
        ),
        encoding="utf-8",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description="PopugVPocket mock catalog builder")
    sub = parser.add_subparsers(dest="command", required=True)
    build = sub.add_parser("build")
    build.add_argument("source", nargs="?", default="dist/cartridges")
    build.add_argument("--output", default="store/mock_catalog.json")
    args = parser.parse_args()
    if args.command == "build":
        build_catalog((ROOT / args.source).resolve(), (ROOT / args.output).resolve())
        print(f"[OK] Catalog written: {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
