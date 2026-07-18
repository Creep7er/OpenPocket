#!/usr/bin/env python3
"""Focused checks for .pctrg validation edge cases."""

from __future__ import annotations

import json
import tempfile
import zipfile
from pathlib import Path

import cartridge_builder


def write_archive(path: Path, manifest: dict, content: bytes, extra_name: str | None = None) -> None:
    with zipfile.ZipFile(path, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("cartridge.json", json.dumps(manifest))
        archive.writestr("content.pck", content)
        if extra_name:
            archive.writestr(extra_name, b"bad")


def base_manifest(content_sha: str) -> dict:
    return {
        "format_version": 2,
        "id": "org.example.valid",
        "name": "Valid",
        "version": "1.0.0",
        "type": "game",
        "entry_scene": "res://cartridges/org.example.valid/main.tscn",
        "sdk_version": "0.5.1",
        "runtime": {"min_version": "0.3.1", "max_version": None},
        "author": {"name": "Tester"},
        "description": "Validation fixture.",
        "capabilities": ["storage"],
        "content": {"file": "content.pck", "sha256": content_sha},
        "signature": None,
    }


def expect_failure(path: Path, label: str) -> None:
    try:
        cartridge_builder.inspect(path)
    except SystemExit:
        return
    raise AssertionError(f"Expected failure for {label}")


def main() -> int:
    with tempfile.TemporaryDirectory() as temp_dir:
        root = Path(temp_dir)
        content = b"GDPC" + b"focused validation fixture"
        content_sha = cartridge_builder.hashlib.sha256(content).hexdigest()
        valid = root / "valid.pctrg"
        write_archive(valid, base_manifest(content_sha), content)
        cartridge_builder.inspect(valid)

        bad_checksum = root / "bad-checksum.pctrg"
        write_archive(bad_checksum, base_manifest("0" * 64), content)
        expect_failure(bad_checksum, "checksum mismatch")

        traversal = root / "traversal.pctrg"
        write_archive(traversal, base_manifest(content_sha), content, "../evil.txt")
        expect_failure(traversal, "path traversal")

    print("PopugVPocket cartridge format checks passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
