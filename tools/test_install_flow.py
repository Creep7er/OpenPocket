#!/usr/bin/env python3
"""Focused install/update/repair/uninstall flow for two external cartridges."""

from __future__ import annotations

import json
import shutil
import tempfile
import zipfile
from pathlib import Path

import cartridge_builder


ROOT = Path(__file__).resolve().parents[1]
V1 = ROOT / "store" / "test_fixtures" / "org.popugonet.popugvpocket.pixelclock-1.0.0.pctrg"
V11 = ROOT / "store" / "mock_packages" / "org.popugonet.popugvpocket.pixelclock-1.1.0.pctrg"
DICE = ROOT / "store" / "mock_packages" / "org.popugonet.popugvpocket.dice-1.0.0.pctrg"


def install(archive_path: Path, packages: Path, registry: dict) -> dict:
    inspected = cartridge_builder.inspect(archive_path)
    package_id = str(inspected.manifest["id"])
    staging = packages.parent / "staging" / package_id
    final = packages / package_id
    backup = packages / f"{package_id}.backup"
    shutil.rmtree(staging, ignore_errors=True)
    shutil.rmtree(backup, ignore_errors=True)
    staging.mkdir(parents=True)
    with zipfile.ZipFile(archive_path) as archive:
        archive.extractall(staging)
    if final.exists():
        final.rename(backup)
    staging.rename(final)
    shutil.rmtree(backup, ignore_errors=True)
    record = dict(inspected.manifest)
    record.update(
        install_source="file",
        trust="untrusted",
        install_path=str(final),
        content_path=str(final / "content.pck"),
        enabled=True,
    )
    registry[package_id] = record
    assert (final / "content.pck").read_bytes()[:4] == b"GDPC"
    return record


def uninstall(package_id: str, packages: Path, registry: dict, storage: dict, remove_data: bool) -> None:
    shutil.rmtree(packages / package_id)
    registry.pop(package_id, None)
    if remove_data:
        storage["packages"].pop(package_id, None)


def main() -> int:
    package_id = "org.popugonet.popugvpocket.pixelclock"
    with tempfile.TemporaryDirectory() as temp:
        root = Path(temp)
        packages = root / "packages"
        packages.mkdir()
        registry: dict = {}
        storage = {"packages": {}}

        first = install(V1, packages, registry)
        assert first["version"] == "1.0.0"
        storage["packages"][package_id] = {"settings": {"hour_24": False}, "data": {}}

        uninstall(package_id, packages, registry, storage, remove_data=False)
        assert storage["packages"][package_id]["settings"]["hour_24"] is False
        install(V1, packages, registry)
        assert storage["packages"][package_id]["settings"]["hour_24"] is False

        updated = install(V11, packages, registry)
        assert updated["version"] == "1.1.0"
        assert storage["packages"][package_id]["settings"]["hour_24"] is False

        uninstall(package_id, packages, registry, storage, remove_data=True)
        assert package_id not in storage["packages"]
        install(V11, packages, registry)
        assert package_id not in storage["packages"]

        dice_id = "org.popugonet.popugvpocket.dice"
        dice = install(DICE, packages, registry)
        assert dice["version"] == "1.0.0"
        (packages / dice_id / "content.pck").unlink()
        assert not (packages / dice_id / "content.pck").exists()
        repaired = install(DICE, packages, registry)
        assert repaired["id"] == dice_id
        uninstall(dice_id, packages, registry, storage, remove_data=False)

        corrupt = root / "checksum-failure.pctrg"
        with zipfile.ZipFile(V11) as source, zipfile.ZipFile(corrupt, "w") as target:
            for name in source.namelist():
                data = source.read(name)
                if name == "content.pck":
                    data = data + b"corrupt"
                target.writestr(name, data)
        try:
            cartridge_builder.inspect(corrupt)
        except SystemExit:
            pass
        else:
            raise AssertionError("checksum mismatch was accepted")

        (root / "result.json").write_text(json.dumps(registry), encoding="utf-8")

    print("Pixel Clock and Dice install/update/repair/uninstall flow passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
