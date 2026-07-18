#!/usr/bin/env python3
"""Validate a clean PopugVPocket public source snapshot."""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path


REQUIRED_FILES = {
    ".gitignore",
    "AGENTS.md",
    "ARCHITECTURE.md",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "README.md",
    "ROADMAP.md",
    "SECURITY.md",
    "THIRD_PARTY.md",
    "export_presets.cfg",
    "project.godot",
}
REQUIRED_DIRECTORIES = {".github", ".codex", "android", "app", "cartridges", "docs", "packages", "sdk", "store", "tools"}
REQUIRED_SCREENSHOTS = {
    "home.png",
    "library.png",
    "store.png",
    "snake.png",
    "pong.png",
    "breakout.png",
    "notes.png",
    "install-cartridge.png",
    "cartridge-details.png",
    "popugvpocket-hero.png",
}
FORBIDDEN_DIRECTORY_NAMES = {".git", ".godot", ".tools", ".tmp", ".cache", "exports", "dist", "publication", "__pycache__"}
FORBIDDEN_SUFFIXES = {".apk", ".aab", ".jks", ".keystore", ".p12", ".pfx", ".pem", ".pyc"}
TEXT_SUFFIXES = {".gd", ".tscn", ".tres", ".json", ".md", ".py", ".ps1", ".yml", ".yaml", ".cfg", ".txt", ".kt", ".kts", ".xml", ".gradle"}
SECRET_PATTERNS = {
    "GitHub token": re.compile(r"(?:ghp_|github_pat_)[A-Za-z0-9_]{20,}"),
    "Google API key": re.compile(r"AIza[0-9A-Za-z_-]{20,}"),
    "OpenAI-style key": re.compile(r"\bsk-[A-Za-z0-9_-]{20,}"),
    "private key": re.compile(r"BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY"),
}
WINDOWS_PATH = re.compile(r"\b[A-Za-z]:[\\/](?:Users|Documents and Settings|ProgramData|Windows|Program Files)(?:[\\/]|\b)", re.IGNORECASE)
MARKDOWN_LINK = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def text_files(root: Path) -> list[Path]:
    return [path for path in root.rglob("*") if path.is_file() and (path.suffix.lower() in TEXT_SUFFIXES or path.name in {"LICENSE", ".gitignore"})]


def validate_tree(root: Path, errors: list[str]) -> None:
    for relative in sorted(REQUIRED_FILES):
        if not (root / relative).is_file():
            fail(errors, f"Missing required file: {relative}")
    for relative in sorted(REQUIRED_DIRECTORIES):
        if not (root / relative).is_dir():
            fail(errors, f"Missing required directory: {relative}/")

    for path in root.rglob("*"):
        relative = path.relative_to(root).as_posix()
        if path.is_dir() and path.name in FORBIDDEN_DIRECTORY_NAMES:
            fail(errors, f"Forbidden directory: {relative}/")
        if path.is_file() and path.suffix.lower() in FORBIDDEN_SUFFIXES:
            fail(errors, f"Forbidden binary or credential: {relative}")
        if path.name == ".publication-notes.md":
            fail(errors, "Publication notes must remain outside the transferable snapshot")
        if path.is_symlink():
            fail(errors, f"Symlink is not allowed in snapshot: {relative}")


def validate_text(root: Path, errors: list[str]) -> None:
    for path in text_files(root):
        relative = path.relative_to(root).as_posix()
        try:
            content = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            fail(errors, f"Text file is not UTF-8: {relative}")
            continue
        if WINDOWS_PATH.search(content):
            fail(errors, f"Absolute Windows path found: {relative}")
        if "file:" + "//" in content.lower():
            fail(errors, f"Local file URL found: {relative}")
        for label, pattern in SECRET_PATTERNS.items():
            if pattern.search(content):
                fail(errors, f"Possible {label} found: {relative}")
        if path.suffix.lower() == ".md" and len(content.strip()) < 40:
            fail(errors, f"Empty or placeholder documentation: {relative}")


def validate_json(root: Path, errors: list[str]) -> None:
    for path in root.rglob("*.json"):
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            fail(errors, f"Invalid JSON {path.relative_to(root).as_posix()}: {exc}")


def validate_links(root: Path, errors: list[str]) -> None:
    for path in root.rglob("*.md"):
        content = path.read_text(encoding="utf-8")
        for raw_target in MARKDOWN_LINK.findall(content):
            target = raw_target.strip().strip("<>").split()[0]
            if target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            target_path = target.split("#", 1)[0]
            if not target_path:
                continue
            resolved = (path.parent / target_path).resolve()
            try:
                resolved.relative_to(root.resolve())
            except ValueError:
                fail(errors, f"Link escapes snapshot in {path.relative_to(root)}: {target}")
                continue
            if not resolved.exists():
                fail(errors, f"Broken relative link in {path.relative_to(root)}: {target}")


def validate_version_and_screenshots(root: Path, errors: list[str]) -> None:
    project = (root / "project.godot").read_text(encoding="utf-8") if (root / "project.godot").exists() else ""
    presets = (root / "export_presets.cfg").read_text(encoding="utf-8") if (root / "export_presets.cfg").exists() else ""
    readme = (root / "README.md").read_text(encoding="utf-8") if (root / "README.md").exists() else ""
    if 'config/version="0.3.2"' not in project:
        fail(errors, "project.godot does not declare version 0.3.2")
    if 'version/name="0.3.2"' not in presets or "version/code=5" not in presets:
        fail(errors, "Android versionName 0.3.2 / versionCode 5 is missing")
    if "first public source snapshot" not in readme.lower():
        fail(errors, "README does not identify 0.3.2 as the first public source snapshot")
    screenshot_root = root / "docs" / "screenshots"
    found = {path.name for path in screenshot_root.glob("*.png")} if screenshot_root.exists() else set()
    for missing in sorted(REQUIRED_SCREENSHOTS - found):
        fail(errors, f"Missing required screenshot: docs/screenshots/{missing}")
    for path in screenshot_root.glob("*.png") if screenshot_root.exists() else []:
        if path.stat().st_size == 0:
            fail(errors, f"Empty screenshot: {path.relative_to(root)}")
            continue
        with path.open("rb") as handle:
            header = handle.read(24)
        if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n":
            fail(errors, f"Invalid PNG screenshot: {path.relative_to(root)}")
            continue
        width, height = struct.unpack(">II", header[16:24])
        expected = (1235, 884) if path.name == "popugvpocket-hero.png" else (393, 852)
        if (width, height) != expected:
            fail(errors, f"Unexpected screenshot size {width}x{height}: {path.relative_to(root)}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", default="publication/popugvpocket-0.3.2")
    args = parser.parse_args()
    root = Path(args.path).resolve()
    if not root.is_dir():
        print(f"[FAIL] Snapshot directory not found: {root}")
        return 1

    errors: list[str] = []
    validate_tree(root, errors)
    validate_text(root, errors)
    validate_json(root, errors)
    validate_links(root, errors)
    validate_version_and_screenshots(root, errors)
    if errors:
        for error in errors:
            print(f"[FAIL] {error}")
        print(f"Publication validation failed with {len(errors)} error(s).")
        return 1

    files = [path for path in root.rglob("*") if path.is_file()]
    size = sum(path.stat().st_size for path in files)
    print(f"[OK] Publication snapshot valid: {root}")
    print(f"[OK] Files: {len(files)}")
    print(f"[OK] Bytes: {size}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
