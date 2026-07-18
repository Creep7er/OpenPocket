#!/usr/bin/env python3
"""Write CI-only Android release signing options into export_presets.cfg."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--preset-file", type=Path, default=Path("export_presets.cfg"))
    parser.add_argument("--keystore", required=True)
    parser.add_argument("--alias", required=True)
    parser.add_argument("--password", required=True)
    args = parser.parse_args()
    text = args.preset_file.read_text(encoding="utf-8")
    signing = (
        "package/signed=true\n"
        f'keystore/release="{args.keystore.replace(chr(92), "/")}"\n'
        f'keystore/release_user="{args.alias}"\n'
        f'keystore/release_password="{args.password}"'
    )
    text, count = re.subn(r"^package/signed=(?:true|false)$", signing, text, flags=re.MULTILINE)
    if count == 0:
        raise SystemExit("No Android signing options found in preset file.")
    args.preset_file.write_text(text, encoding="utf-8")
    print("Configured temporary Android release signing options.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
