#!/usr/bin/env python3
"""Small repository-level checks for OpenPocket package logic."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def fail(message: str) -> None:
    print(f"ERROR: {message}")
    raise SystemExit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def require(pattern: str, text: str, message: str) -> None:
    if not re.search(pattern, text, re.MULTILINE):
        fail(message)


def test_package_settings_api() -> None:
    storage = read("app/runtime/storage/pocket_storage.gd")
    for method in [
        "get_package_setting",
        "set_package_setting",
        "reset_package_settings",
        "get_package_data",
        "set_package_data",
        "clear_package_store",
    ]:
        require(rf"func {method}\(", storage, f"PocketStorage misses {method}")
    require(r'package_store\["settings"\]', storage, "Package settings namespace missing")
    require(r'package_store\["data"\]', storage, "Package data namespace missing")


def test_snake_logic_files() -> None:
    config = read("packages/games/snake/snake_config.gd")
    rules = read("packages/games/snake/snake_rules.gd")
    main = read("packages/games/snake/main.gd")
    for difficulty in ["easy", "normal", "hard", "extreme"]:
        require(rf'"{difficulty}"', config, f"Snake difficulty missing: {difficulty}")
    require(r"static func is_reverse", rules, "Snake reverse-direction helper missing")
    require(r"wrap", rules, "Snake wrap logic missing")
    require(r"SCREEN_SETTINGS", main, "Snake settings screen missing")
    require(r"time_attack", main, "Snake time attack mode missing")
    require(r"statistics", main, "Snake statistics persistence missing")


def test_pong_logic_files() -> None:
    config = read("packages/games/pong/pong_config.gd")
    rules = read("packages/games/pong/pong_rules.gd")
    main = read("packages/games/pong/main.gd")
    for difficulty in ["easy", "normal", "hard"]:
        require(rf'"{difficulty}"', config, f"Pong CPU difficulty missing: {difficulty}")
    require(r"match_finished", rules, "Pong match target helper missing")
    require(r"capped_velocity", rules, "Pong ball speed cap helper missing")
    require(r"SCREEN_SETTINGS", main, "Pong settings screen missing")
    require(r"statistics", main, "Pong statistics persistence missing")


def test_package_index_json() -> None:
    index = json.loads(read("packages/index.json"))
    expected = {"games/snake", "games/pong", "apps/notes"}
    actual = set(index.get("packages", []))
    missing = expected - actual
    if missing:
        fail("Package index misses: " + ", ".join(sorted(missing)))


def test_cartridge_runtime_files() -> None:
    manager = read("app/runtime/cartridges/cartridge_manager.gd")
    installer = read("app/runtime/cartridges/cartridge_installer.gd")
    shell = read("app/shell/shell_view.gd")
    for method in [
        "list_installed",
        "list_builtin",
        "install_from_file",
        "uninstall",
        "launch",
        "verify",
    ]:
        require(rf"func {method}\(", manager, f"CartridgeManager misses {method}")
    for guard in ["MAX_ARCHIVE_SIZE", "MAX_EXTRACTED_SIZE", "MAX_FILES", "Traversal paths are rejected", "checksum mismatch"]:
        require(re.escape(guard), installer, f"CartridgeInstaller misses guard: {guard}")
    require(r"DEVELOPER MODE", shell, "Developer Mode warning UI missing")
    require(r"func show_store\(\)", shell, "Store UI entry point missing")
    require(r'_render\("STORE",', shell, "Store title missing")
    for section in ["Featured", "All", "Updates", "Search"]:
        require(rf'"label": "{section}"', shell, f"Store section missing: {section}")


def test_cartridge_manifests() -> None:
    for path in [
        "packages/games/snake/cartridge.json",
        "packages/games/pong/cartridge.json",
        "packages/apps/notes/cartridge.json",
    ]:
        manifest = json.loads(read(path))
        for field in ["format_version", "id", "name", "version", "entry_scene", "content"]:
            if field not in manifest:
                fail(f"{path} misses {field}")
        if manifest["format_version"] != 1:
            fail(f"{path} must use cartridge format 1")


def test_store_catalog() -> None:
    catalog = json.loads(read("store/mock_catalog.json"))
    if catalog.get("schema_version") != 1:
        fail("Store catalog schema_version must be 1")
    for entry in catalog.get("cartridges", []):
        for field in ["id", "name", "version", "download", "sha256", "curated"]:
            if field not in entry:
                fail(f"Store catalog entry misses {field}")


def main() -> int:
    test_package_settings_api()
    test_snake_logic_files()
    test_pong_logic_files()
    test_package_index_json()
    test_cartridge_runtime_files()
    test_cartridge_manifests()
    test_store_catalog()
    print("OpenPocket package logic checks passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
