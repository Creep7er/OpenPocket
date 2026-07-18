#!/usr/bin/env python3
"""Validate the PopugVPocket MVP repository structure."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import validate_version


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_FILES = [
    "project.godot",
    "config/product.json",
    "AGENTS.md",
    "README.md",
    "ARCHITECTURE.md",
    "CONTRIBUTING.md",
    "CODE_OF_CONDUCT.md",
    "LICENSE",
    "app/main.tscn",
    "app/main.gd",
    "app/runtime/input/pocket_input.gd",
    "app/runtime/audio/pocket_audio.gd",
    "app/runtime/audio/cartridge_audio.gd",
    "app/runtime/packages/pocket_packages.gd",
    "app/runtime/cartridges/cartridge_manager.gd",
    "app/runtime/cartridges/cartridge_installer.gd",
    "app/runtime/cartridges/cartridge_loader.gd",
    "app/runtime/files/pocket_file_picker.gd",
    "app/runtime/migration/legacy_backup_importer.gd",
    "app/runtime/branding/brand_config.gd",
    "app/runtime/layout/console_layout_manager.gd",
    "app/runtime/screen/pocket_screen.gd",
    "app/runtime/store/store_service.gd",
    "app/runtime/store/store_download_manager.gd",
    "app/runtime/store/store_download_job.gd",
    "app/runtime/store/local_store_provider.gd",
    "app/runtime/storage/pocket_storage.gd",
    "app/runtime/system/pocket_router.gd",
    "app/runtime/system/pocket_system.gd",
    "app/ui/package_settings/package_setting_definition.gd",
    "app/ui/package_settings/package_settings_renderer.gd",
    "app/ui/package_settings/package_settings_view.gd",
    ".github/workflows/release.yml",
    "tools/layout_preview.tscn",
    "tools/vgirl_layout_audit.tscn",
    "packages/games/snake/manifest.json",
    "packages/games/snake/cartridge.json",
    "packages/games/snake/main.tscn",
    "packages/games/snake/main.gd",
    "packages/games/snake/README.md",
    "packages/games/snake/snake_config.gd",
    "packages/games/snake/snake_rules.gd",
    "packages/games/snake/snake_statistics.gd",
    "packages/games/pong/manifest.json",
    "packages/games/pong/cartridge.json",
    "packages/games/pong/main.tscn",
    "packages/games/pong/main.gd",
    "packages/games/pong/README.md",
    "packages/games/pong/pong_config.gd",
    "packages/games/pong/pong_rules.gd",
    "packages/games/pong/pong_cpu_controller.gd",
    "packages/games/pong/pong_statistics.gd",
    "packages/index.json",
    "packages/apps/notes/manifest.json",
    "packages/apps/notes/cartridge.json",
    "packages/apps/notes/main.tscn",
    "packages/apps/notes/main.gd",
    "sdk/templates/game/manifest.json",
    "sdk/templates/game/main.tscn",
    "sdk/templates/game/main.gd",
    "sdk/templates/app/manifest.json",
    "sdk/templates/app/main.tscn",
    "sdk/templates/app/main.gd",
    "sdk/templates/cartridge-game/cartridge.json",
    "sdk/templates/cartridge-game/main.tscn",
    "sdk/templates/cartridge-game/main.gd",
    "sdk/templates/cartridge-app/cartridge.json",
    "sdk/templates/cartridge-app/main.tscn",
    "sdk/templates/cartridge-app/main.gd",
    "sdk/schemas/package.schema.json",
    "sdk/schemas/cartridge.schema.json",
    "sdk/docs/creating-a-game.md",
    "sdk/docs/creating-an-app.md",
    "sdk/docs/input-api.md",
    "sdk/docs/storage-api.md",
    "sdk/docs/audio-api.md",
    "sdk/docs/lifecycle.md",
    "sdk/docs/cartridge-format.md",
    "sdk/docs/building-cartridges.md",
    "sdk/docs/installing-cartridges.md",
    "sdk/docs/cartridge-lifecycle.md",
    "sdk/docs/cartridge-storage.md",
    "sdk/docs/cartridge-security.md",
    "sdk/docs/store-provider.md",
    "tools/cartridge_builder.py",
    "tools/cartridge_catalog.py",
    "tools/analyze_apk.py",
    "tools/build_android_artifacts.ps1",
    "tools/capture_publication_screenshots.tscn",
    "tools/prepare_publication.py",
    "tools/validate_publication.py",
    "tools/test_cartridge_format.py",
    "tools/test_install_flow.py",
    "store/mock_catalog.json",
    "android/plugins/popugvpocket_file_picker/plugin/src/main/java/org/popugonet/popugvpocket/filepicker/PopugVPocketFilePicker.kt",
    "docs/android-build.md",
    "docs/branding.md",
    "docs/layout-profiles.md",
    "docs/controls.md",
    "docs/reborn-migration.md",
    "docs/releases/0.5.0.md",
    "SECURITY.md",
    "ROADMAP.md",
    "CHANGELOG.md",
    "THIRD_PARTY.md",
    "docs/README.ru.md",
    "docs/releases/0.3.2.md",
    ".github/workflows/android-compact.yml",
]

MANIFEST_REQUIRED = ["id", "name", "version", "type", "entry_scene", "sdk_version", "author"]
CARTRIDGE_REQUIRED = [
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
SUPPORTED_CAPABILITIES = {"storage", "audio", "theme", "system_menu"}


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    raise SystemExit(1)


def validate_required_files() -> None:
    missing = [path for path in REQUIRED_FILES if not (ROOT / path).exists()]
    if missing:
        fail("Missing required files:\n" + "\n".join(f"  - {path}" for path in missing))


def load_json(path: Path) -> dict:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except json.JSONDecodeError as exc:
        fail(f"Invalid JSON in {path.relative_to(ROOT)}: {exc}")
    if not isinstance(data, dict):
        fail(f"Manifest must be a JSON object: {path.relative_to(ROOT)}")
    return data


def validate_manifests() -> None:
    index = load_json(ROOT / "packages/index.json")
    indexed_packages = index.get("packages")
    if not isinstance(indexed_packages, list) or not indexed_packages:
        fail("packages/index.json must contain a non-empty packages array")

    package_root = ROOT / "packages"
    manifests = sorted(package_root.glob("**/manifest.json"))
    if not manifests:
        fail("No package manifests found under packages/")

    seen_ids: set[str] = set()
    seen_paths: set[str] = set()
    for manifest_path in manifests:
        manifest = load_json(manifest_path)
        missing = [key for key in MANIFEST_REQUIRED if key not in manifest]
        if missing:
            fail(f"{manifest_path.relative_to(ROOT)} misses fields: {', '.join(missing)}")

        package_id = str(manifest["id"])
        if package_id in seen_ids:
            fail(f"Duplicate package id: {package_id}")
        seen_ids.add(package_id)

        entry_scene = manifest_path.parent / str(manifest["entry_scene"])
        if not entry_scene.exists():
            fail(f"Entry scene missing for {package_id}: {entry_scene.relative_to(ROOT)}")

        cartridge_path = manifest_path.parent / "cartridge.json"
        if not cartridge_path.exists():
            fail(f"Missing cartridge manifest for {package_id}: {cartridge_path.relative_to(ROOT)}")
        validate_cartridge_manifest(cartridge_path, manifest)

        if manifest_path.parent.parent.name not in {"games", "apps", "themes", "firmware", "skills"}:
            fail(f"Unexpected package location: {manifest_path.relative_to(ROOT)}")

        package_entry = manifest_path.parent.relative_to(package_root).as_posix()
        seen_paths.add(package_entry)

    indexed_set = {str(entry).strip("/") for entry in indexed_packages}
    missing_from_index = sorted(seen_paths - indexed_set)
    missing_on_disk = sorted(indexed_set - seen_paths)
    if missing_from_index:
        fail("Package manifests missing from packages/index.json:\n" + "\n".join(f"  - {path}" for path in missing_from_index))
    if missing_on_disk:
        fail("packages/index.json points to missing packages:\n" + "\n".join(f"  - {path}" for path in missing_on_disk))


def validate_external_sources() -> None:
    source_root = ROOT / "cartridges" / "source"
    seen_versions: set[tuple[str, str]] = set()
    for manifest_path in sorted(source_root.glob("*/manifest.json")):
        manifest = load_json(manifest_path)
        missing = [key for key in MANIFEST_REQUIRED if key not in manifest]
        if missing:
            fail(f"{manifest_path.relative_to(ROOT)} misses fields: {', '.join(missing)}")
        package_id = str(manifest["id"])
        version = str(manifest["version"])
        identity = (package_id, version)
        if identity in seen_versions:
            fail(f"Duplicate external cartridge version: {package_id} {version}")
        seen_versions.add(identity)
        if not (manifest_path.parent / str(manifest["entry_scene"])).exists():
            fail(f"External entry scene missing: {manifest_path.relative_to(ROOT)}")
        cartridge_path = manifest_path.parent / "cartridge.json"
        validate_cartridge_manifest(cartridge_path, manifest)
        cartridge = load_json(cartridge_path)
        expected_root = f"res://cartridges/{package_id}/"
        if not str(cartridge.get("entry_scene", "")).startswith(expected_root):
            fail(f"External entry scene must use {expected_root}: {cartridge_path.relative_to(ROOT)}")


def validate_cartridge_manifest(cartridge_path: Path, package_manifest: dict) -> None:
    cartridge = load_json(cartridge_path)
    missing = [key for key in CARTRIDGE_REQUIRED if key not in cartridge]
    if missing:
        fail(f"{cartridge_path.relative_to(ROOT)} misses fields: {', '.join(missing)}")
    if cartridge.get("format_version") != 2:
        fail(f"{cartridge_path.relative_to(ROOT)} must use PopugVPocket format_version 2")
    if cartridge.get("id") != package_manifest.get("id"):
        fail(f"Cartridge id does not match package manifest: {cartridge_path.relative_to(ROOT)}")
    if cartridge.get("type") not in {"game", "app", "theme"}:
        fail(f"Unsupported cartridge type in {cartridge_path.relative_to(ROOT)}")
    if cartridge.get("type") == "theme":
        fail(f"Theme cartridges validate in schema only; runtime support is future: {cartridge_path.relative_to(ROOT)}")
    author = cartridge.get("author")
    if not isinstance(author, dict) or not str(author.get("name", "")).strip():
        fail(f"Cartridge author.name is required: {cartridge_path.relative_to(ROOT)}")
    content = cartridge.get("content")
    if not isinstance(content, dict) or content.get("file") != "content.pck":
        fail(f"Cartridge content.file must be content.pck: {cartridge_path.relative_to(ROOT)}")
    sha = str(content.get("sha256", ""))
    if not re.fullmatch(r"[a-fA-F0-9]{64}", sha):
        fail(f"Cartridge content.sha256 must be a SHA-256 hex string: {cartridge_path.relative_to(ROOT)}")
    capabilities = cartridge.get("capabilities", [])
    if isinstance(capabilities, dict):
        capabilities = capabilities.get("required", [])
    unsupported = sorted({str(item) for item in capabilities} - SUPPORTED_CAPABILITIES)
    if unsupported:
        fail(f"Unsupported cartridge capabilities in {cartridge_path.relative_to(ROOT)}: {', '.join(unsupported)}")


def validate_package_boundaries() -> None:
    forbidden = {
        "FileAccess": re.compile(r"\bFileAccess\b"),
        "Input": re.compile(r"\bInput\."),
        "AudioServer": re.compile(r"\bAudioServer\b"),
        "Shell PocketAudio": re.compile(r"\bPocketAudio\."),
    }
    violations: list[str] = []
    scripts = list((ROOT / "packages").glob("**/*.gd"))
    scripts += list((ROOT / "cartridges" / "source").glob("**/*.gd"))
    for script_path in sorted(scripts):
        text = script_path.read_text(encoding="utf-8")
        for label, pattern in forbidden.items():
            if pattern.search(text):
                violations.append(f"{script_path.relative_to(ROOT)} uses {label}")
    if violations:
        fail("Package boundary violations:\n" + "\n".join(f"  - {entry}" for entry in violations))


def validate_legacy_name_allowlist() -> None:
    allowed_paths = {
        "CHANGELOG.md",
        "ARCHITECTURE.md",
        "docs/reborn-migration.md",
        "docs/releases/0.3.2.md",
        "docs/releases/0.4.0.md",
        "docs/releases/0.5.0.md",
        "app/runtime/migration/legacy_backup_importer.gd",
        "tools/reborn_runtime_test.gd",
        "tools/validate_project.py",
    }
    suffixes = {".md", ".gd", ".json", ".py", ".cfg", ".godot", ".yml", ".yaml", ".ps1"}
    violations: list[str] = []
    pattern = re.compile(r"org\.openpocket|\bopenpocket\b", re.IGNORECASE)
    for path in ROOT.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in suffixes:
            continue
        relative = path.relative_to(ROOT).as_posix()
        if relative.startswith((".git/", ".godot/", "android/build/", "artifacts/", "build/", "exports/")):
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
            if not pattern.search(line):
                continue
            actual_repository_url = "github.com/Creep7er/OpenPocket" in line or "openpocket-catalog" in line or "openpocket-game-template" in line or "openpocket-app-template" in line
            legacy_ui = relative == "app/shell/shell_view.gd" and "LEGACY OPENPOCKET" in line
            if relative not in allowed_paths and not actual_repository_url and not legacy_ui:
                violations.append(f"{relative}:{number}")
    if violations:
        fail("Deprecated OpenPocket name outside allowlist:\n" + "\n".join(f"  - {entry}" for entry in violations))


def main() -> int:
    validate_version.main()
    validate_required_files()
    validate_manifests()
    validate_external_sources()
    validate_package_boundaries()
    validate_legacy_name_allowlist()
    print("PopugVPocket validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
