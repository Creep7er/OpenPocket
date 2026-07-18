#!/usr/bin/env python3
"""Build, validate, and inspect PopugVPocket .pctrg cartridge archives."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
DIST = ROOT / "dist" / "cartridges"
FORMAT_VERSION = 2
MAX_ARCHIVE_SIZE = 64 * 1024 * 1024
MAX_EXTRACTED_SIZE = 128 * 1024 * 1024
MAX_FILES = 512
MAX_PATH_LENGTH = 180
ALLOWED_EXTRA_ROOTS = {"screenshots", "assets"}
SUPPORTED_TYPES = {"game", "app", "theme"}
RUNTIME_TYPES = {"game", "app"}
SUPPORTED_CAPABILITIES = {"storage", "audio", "theme", "system_menu"}
EXCLUDED_NAMES = {".git", ".godot", "__pycache__"}
GODOT_CANDIDATES = [
    ROOT / ".tools" / "godot" / "Godot_v4.7-stable_win64_console.exe",
    ROOT / ".tools" / "godot" / "Godot_v4.7-stable_win64.exe",
]
TEXT_RESOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".json", ".md"}


@dataclass
class InspectResult:
    manifest: dict[str, Any]
    archive_sha256: str
    content_sha256: str
    size: int
    files: list[str]


def fail(message: str) -> None:
    print(f"[FAIL] {message}")
    raise SystemExit(1)


def ok(message: str) -> None:
    print(f"[OK] {message}")


def read_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        fail(f"Invalid JSON in {path}: {exc}")
    if not isinstance(data, dict):
        fail(f"JSON must be an object: {path}")
    return data


def normalize_author(value: Any) -> dict[str, str]:
    if isinstance(value, dict):
        return {"name": str(value.get("name", "Unknown")), "url": str(value.get("url", ""))}
    return {"name": str(value), "url": ""}


def package_manifest_to_cartridge(package_dir: Path) -> dict[str, Any]:
    manifest = read_json(package_dir / "manifest.json")
    package_id = str(manifest.get("id", ""))
    rel_scene = str(manifest.get("entry_scene", "main.tscn"))
    return {
        "format_version": FORMAT_VERSION,
        "id": package_id,
        "name": str(manifest.get("name", package_id)),
        "version": str(manifest.get("version", "0.5.0-dev")),
        "type": str(manifest.get("type", "game")),
        "entry_scene": f"res://cartridges/{package_id}/{Path(rel_scene).name}",
        "sdk_version": "0.5.0",
        "runtime": {"min_version": "0.5.0", "max_version": None},
        "author": normalize_author(manifest.get("author", "PopugVPocket Contributors")),
        "description": str(manifest.get("description", "PopugVPocket cartridge.")),
        "category": str(manifest.get("category", "misc")),
        "icon": str(manifest.get("icon", "icon.png")),
        "license": str(manifest.get("license", "MIT")),
        "capabilities": list(manifest.get("capabilities", ["storage", "audio", "theme"])),
        "permissions": [],
        "content": {"file": "content.pck", "sha256": "0" * 64},
        "signature": None,
        "store": {"featured": False, "tags": []},
    }


def load_cartridge_manifest(package_dir: Path) -> dict[str, Any]:
    cartridge_path = package_dir / "cartridge.json"
    if cartridge_path.exists():
        manifest = read_json(cartridge_path)
        cartridge_id = str(manifest.get("id", ""))
        manifest["entry_scene"] = f"res://cartridges/{cartridge_id}/{Path(str(manifest.get('entry_scene', 'main.tscn'))).name}"
        manifest["sdk_version"] = "0.5.0"
        manifest["runtime"] = {"min_version": "0.5.0", "max_version": None}
        return manifest
    return package_manifest_to_cartridge(package_dir)


def capability_list(manifest: dict[str, Any]) -> list[str]:
    value = manifest.get("capabilities", [])
    if isinstance(value, dict):
        return [str(item) for item in value.get("required", [])]
    return [str(item) for item in value]


def validate_manifest(manifest: dict[str, Any], require_checksum: bool) -> None:
    required = [
        "format_version",
        "id",
        "name",
        "version",
        "type",
        "entry_scene",
        "sdk_version",
        "runtime",
        "author",
        "description",
        "content",
    ]
    missing = [key for key in required if key not in manifest]
    if missing:
        fail("Manifest missing fields: " + ", ".join(missing))
    if manifest["format_version"] != FORMAT_VERSION:
        fail("Unsupported cartridge format_version")
    cartridge_type = str(manifest["type"])
    if cartridge_type not in SUPPORTED_TYPES:
        fail(f"Unsupported cartridge type: {cartridge_type}")
    if cartridge_type not in RUNTIME_TYPES:
        fail(f"Runtime support for type is future: {cartridge_type}")
    author = normalize_author(manifest["author"])
    if not author["name"].strip():
        fail("author.name is required")
    content = manifest.get("content")
    if not isinstance(content, dict) or not str(content.get("file", "")).strip():
        fail("content.file is required")
    if require_checksum and len(str(content.get("sha256", ""))) != 64:
        fail("content.sha256 must be a SHA-256 hex string")
    unsupported = sorted(set(capability_list(manifest)) - SUPPORTED_CAPABILITIES)
    if unsupported:
        fail("Unsupported required capabilities: " + ", ".join(unsupported))


def iter_source_files(package_dir: Path) -> list[Path]:
    files: list[Path] = []
    for path in sorted(package_dir.rglob("*")):
        if not path.is_file():
            continue
        rel_parts = set(path.relative_to(package_dir).parts)
        if rel_parts & EXCLUDED_NAMES:
            continue
        if path.name.endswith((".uid", ".import")):
            continue
        if path.name == "cartridge.json":
            continue
        files.append(path)
    return files


def build_content_pack(package_dir: Path, output: Path) -> str:
    manifest = load_cartridge_manifest(package_dir)
    cartridge_id = str(manifest["id"])
    resource_root = f"res://cartridges/{cartridge_id}/"
    source_root = _source_resource_root(package_dir)
    staging_root = ROOT / "build"
    staging_root.mkdir(parents=True, exist_ok=True)
    (staging_root / ".gdignore").touch()
    build_root = staging_root / "cartridge_builder" / f"{cartridge_id}-{manifest['version']}"
    if build_root.exists():
        shutil.rmtree(build_root)
    target = build_root / "cartridges" / cartridge_id
    target.mkdir(parents=True, exist_ok=True)
    for source in iter_source_files(package_dir):
        relative = source.relative_to(package_dir)
        destination = target / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        data = source.read_bytes()
        if source.suffix.lower() in TEXT_RESOURCE_SUFFIXES:
            text = data.decode("utf-8")
            text = text.replace(source_root, resource_root)
            data = text.encode("utf-8")
        destination.write_bytes(data)
    entry_scene = str(manifest["entry_scene"])
    (build_root / "project.godot").write_text(
        "\n".join([
            "; Generated by PopugVPocket Cartridge Builder",
            "config_version=5",
            "",
            "[application]",
            f'config/name="{cartridge_id}"',
            f'run/main_scene="{entry_scene}"',
            "",
            "[rendering]",
            'renderer/rendering_method="gl_compatibility"',
            "textures/default_filters/use_nearest_mipmap_filter=false",
        ]),
        encoding="utf-8",
    )
    (build_root / "export_presets.cfg").write_text(
        "\n".join([
            "[preset.0]",
            "",
            'name="Cartridge"',
            'platform="Windows Desktop"',
            "runnable=false",
            'export_filter="all_resources"',
            'include_filter=""',
            'exclude_filter=""',
            "encrypt_pck=false",
            "encrypt_directory=false",
            "script_export_mode=2",
            "",
            "[preset.0.options]",
            "",
            'custom_template/debug=""',
            'custom_template/release=""',
        ]),
        encoding="utf-8",
    )
    godot = _find_godot()
    output.parent.mkdir(parents=True, exist_ok=True)
    completed = subprocess.run(
        [str(godot), "--headless", "--path", str(build_root), "--export-pack", "Cartridge", str(output)],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if completed.returncode != 0 or not output.exists():
        details = (completed.stdout + "\n" + completed.stderr).strip()
        fail(f"Godot PCK export failed ({completed.returncode}): {details[-2000:]}")
    header = output.read_bytes()[:4]
    if header != b"GDPC":
        fail("Godot export did not produce a valid PCK header")
    if not (target / Path(entry_scene).name).exists():
        fail(f"Entry scene not included in source root: {entry_scene}")
    return hashlib.sha256(output.read_bytes()).hexdigest()


def _source_resource_root(package_dir: Path) -> str:
    try:
        relative = package_dir.relative_to(ROOT).as_posix()
    except ValueError:
        return "res://cartridge/"
    return f"res://{relative}/"


def _find_godot() -> Path:
    configured = os.environ.get("GODOT_BIN", "").strip()
    if configured and Path(configured).exists():
        return Path(configured)
    for candidate in GODOT_CANDIDATES:
        if candidate.exists():
            return candidate
    resolved = shutil.which("godot") or shutil.which("godot4")
    if resolved:
        return Path(resolved)
    fail("Godot executable not found; install Godot or place it under .tools/godot")
    raise AssertionError("unreachable")


def ensure_icon(path: Path) -> bytes:
    if path.exists():
        return path.read_bytes()
    # 1x1 transparent PNG, deterministic placeholder.
    return bytes.fromhex(
        "89504e470d0a1a0a0000000d4948445200000001000000010806000000"
        "1f15c4890000000a49444154789c6360000002000100ffff030000060005"
        "57bfab0000000049454e44ae426082"
    )


def build(package_dir: Path, output_dir: Path) -> Path:
    package_dir = package_dir.resolve()
    if not package_dir.exists():
        fail(f"Package directory not found: {package_dir}")
    manifest = load_cartridge_manifest(package_dir)
    validate_manifest(manifest, require_checksum=False)
    output_dir.mkdir(parents=True, exist_ok=True)
    cartridge_id = str(manifest["id"])
    version = str(manifest["version"])
    temp_content = output_dir / f"_{cartridge_id}-{version}-content.pck"
    content_sha = build_content_pack(package_dir, temp_content)
    manifest = json.loads(json.dumps(manifest))
    manifest["content"] = {"file": "content.pck", "sha256": content_sha}
    manifest.setdefault("signature", None)
    validate_manifest(manifest, require_checksum=True)
    output = output_dir / f"{cartridge_id}-{version}.pctrg"
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        add_bytes(archive, "cartridge.json", json.dumps(manifest, indent=2, sort_keys=True).encode("utf-8"))
        add_bytes(archive, "content.pck", temp_content.read_bytes())
        add_bytes(archive, "icon.png", ensure_icon(package_dir / "icon.png"))
        if (package_dir / "README.md").exists():
            add_bytes(archive, "README.md", (package_dir / "README.md").read_bytes())
        if (package_dir / "LICENSE").exists():
            add_bytes(archive, "LICENSE", (package_dir / "LICENSE").read_bytes())
    temp_content.unlink(missing_ok=True)
    return output


def add_bytes(archive: zipfile.ZipFile, name: str, data: bytes) -> None:
    info = zipfile.ZipInfo(name, date_time=(2026, 1, 1, 0, 0, 0))
    info.compress_type = zipfile.ZIP_DEFLATED
    archive.writestr(info, data)


def validate_entry_name(name: str) -> None:
    normalized = name.replace("\\", "/")
    if len(normalized) > MAX_PATH_LENGTH:
        fail(f"Archive path too long: {name}")
    if normalized.startswith("/") or normalized.startswith("//") or ":" in normalized:
        fail(f"Unsafe archive path: {name}")
    if any(part in {"..", "."} for part in normalized.split("/")):
        fail(f"Path traversal rejected: {name}")


def inspect(path: Path) -> InspectResult:
    if not path.exists():
        fail(f"Cartridge not found: {path}")
    archive_bytes = path.read_bytes()
    if len(archive_bytes) > MAX_ARCHIVE_SIZE:
        fail("Archive exceeds 64 MB MVP limit")
    with zipfile.ZipFile(path, "r") as archive:
        names = archive.namelist()
        if len(names) > MAX_FILES:
            fail("Archive contains too many files")
        lowered = [name.lower() for name in names]
        if len(lowered) != len(set(lowered)):
            fail("Duplicate archive filenames")
        total = 0
        for info in archive.infolist():
            validate_entry_name(info.filename)
            total += info.file_size
            if total > MAX_EXTRACTED_SIZE:
                fail("Extracted content exceeds 128 MB MVP limit")
        if "cartridge.json" not in names or "content.pck" not in names:
            fail("cartridge.json and content.pck are required")
        manifest = json.loads(archive.read("cartridge.json").decode("utf-8"))
        if not isinstance(manifest, dict):
            fail("cartridge.json must be an object")
        validate_manifest(manifest, require_checksum=True)
        content = archive.read("content.pck")
        if len(content) < 4 or content[:4] != b"GDPC":
            fail("content.pck is not a Godot resource pack")
        content_sha = hashlib.sha256(content).hexdigest()
        expected_sha = str(manifest["content"]["sha256"]).lower()
        if content_sha != expected_sha:
            fail("content.pck checksum mismatch")
    return InspectResult(
        manifest=manifest,
        archive_sha256=hashlib.sha256(archive_bytes).hexdigest(),
        content_sha256=content_sha,
        size=len(archive_bytes),
        files=names,
    )


def print_inspect(result: InspectResult) -> None:
    manifest = result.manifest
    author = normalize_author(manifest.get("author", {}))
    print("ID:", manifest.get("id"))
    print("NAME:", manifest.get("name"))
    print("VERSION:", manifest.get("version"))
    print("TYPE:", manifest.get("type"))
    print("AUTHOR:", author["name"])
    print("CAPABILITIES:", ", ".join(capability_list(manifest)) or "none")
    print("CONTENT SHA256:", result.content_sha256)
    print("ARCHIVE SHA256:", result.archive_sha256)
    print("SIZE:", result.size)
    print("FILES:", len(result.files))


def command_build(args: argparse.Namespace) -> int:
    print("PopugVPocket Cartridge Builder\n")
    package_dir = Path(args.package_dir)
    output_dir = Path(args.output_dir)
    if not package_dir.is_absolute():
        package_dir = ROOT / package_dir
    if not output_dir.is_absolute():
        output_dir = ROOT / output_dir
    output = build(package_dir.resolve(), output_dir.resolve())
    result = inspect(output)
    ok("Manifest valid")
    ok("Runnable Godot content pack built")
    ok("SHA-256 calculated")
    ok("Cartridge created")
    print("\nOUTPUT:")
    print(output.relative_to(ROOT))
    print("\nID:", result.manifest["id"])
    print("VERSION:", result.manifest["version"])
    print("TYPE:", result.manifest["type"])
    return 0


def command_validate(args: argparse.Namespace) -> int:
    inspect(Path(args.path))
    ok("Cartridge valid")
    return 0


def command_inspect(args: argparse.Namespace) -> int:
    print_inspect(inspect(Path(args.path)))
    return 0


def command_list(args: argparse.Namespace) -> int:
    root = Path(args.path)
    for path in sorted(root.glob("*.pctrg")):
        result = inspect(path)
        print(f"{result.manifest['id']} {result.manifest['version']} {path}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="PopugVPocket Cartridge Builder")
    sub = parser.add_subparsers(dest="command", required=True)
    build_parser = sub.add_parser("build")
    build_parser.add_argument("package_dir")
    build_parser.add_argument("--output-dir", default=str(DIST))
    build_parser.set_defaults(func=command_build)
    validate_parser = sub.add_parser("validate")
    validate_parser.add_argument("path")
    validate_parser.set_defaults(func=command_validate)
    inspect_parser = sub.add_parser("inspect")
    inspect_parser.add_argument("path")
    inspect_parser.set_defaults(func=command_inspect)
    list_parser = sub.add_parser("list")
    list_parser.add_argument("path", nargs="?", default=str(DIST))
    list_parser.set_defaults(func=command_list)
    args = parser.parse_args()
    try:
        return int(args.func(args))
    except zipfile.BadZipFile:
        fail("Invalid ZIP cartridge")
    return 1


if __name__ == "__main__":
    sys.exit(main())
