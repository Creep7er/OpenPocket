from __future__ import annotations

import json
import os
from pathlib import Path


def require_directory(name: str) -> Path:
    value = os.environ.get(name, "").strip()
    path = Path(value)
    if not value or not path.is_dir():
        raise SystemExit(f"{name} must point to an existing directory")
    return path.resolve()


def main() -> None:
    android_sdk = require_directory("ANDROID_HOME")
    java_sdk = require_directory("JAVA_HOME")
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    settings_path = config_home / "godot" / "editor_settings-4.7.tres"
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    settings_path.write_text(
        "\n".join(
            [
                '[gd_resource type="EditorSettings" format=3]',
                "",
                "[resource]",
                f"export/android/java_sdk_path = {json.dumps(java_sdk.as_posix())}",
                f"export/android/android_sdk_path = {json.dumps(android_sdk.as_posix())}",
                "",
            ]
        ),
        encoding="utf-8",
    )
    print(f"Godot Android editor settings: {settings_path}")


if __name__ == "__main__":
    main()
