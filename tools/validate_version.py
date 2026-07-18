#!/usr/bin/env python3
"""Validate release metadata against config/product.json."""

from __future__ import annotations

import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def require(pattern: str, text: str, label: str) -> None:
    if re.search(pattern, text) is None:
        raise SystemExit(f"[FAIL] version mismatch: {label}")


def main() -> int:
    product = json.loads((ROOT / "config/product.json").read_text(encoding="utf-8"))
    version = re.escape(str(product["version"]))
    version_code = int(product["android"]["version_code"])
    package_id = re.escape(str(product["android"]["package_id"]))
    project = (ROOT / "project.godot").read_text(encoding="utf-8")
    constants = (ROOT / "app/runtime/branding/brand_constants.gd").read_text(encoding="utf-8")
    presets = (ROOT / "export_presets.cfg").read_text(encoding="utf-8")
    require(rf'config/version="{version}"', project, "project.godot")
    require(rf'const VERSION := "{version}"', constants, "BrandConstants")
    if presets.count(f'version/name="{product["version"]}"') != 3:
        raise SystemExit("[FAIL] every Android preset must use the product version")
    if presets.count(f"version/code={version_code}") != 3:
        raise SystemExit("[FAIL] every Android preset must use the product versionCode")
    if presets.count(f'package/unique_name="{product["android"]["package_id"]}"') != 3:
        raise SystemExit(f"[FAIL] every Android preset must use {package_id}")
    if str(product["catalog_url"]) not in constants:
        raise SystemExit("[FAIL] catalog URL differs from product config")
    print(f"PopugVPocket {product['version']} metadata is consistent.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
