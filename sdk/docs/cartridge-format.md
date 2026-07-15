# Cartridge Format

OpenPocket cartridges use `.pctrg`, a ZIP container with MIME type `application/x-openpocket-cartridge`.

Required files:

```text
cartridge.json
content.pck
```

Optional files:

```text
icon.png
README.md
LICENSE
screenshots/*
assets/*
```

`cartridge.json` uses `format_version: 1`. `content.sha256` must match `content.pck`. The current runtime supports `game` and `app`; `theme` is reserved for future support.

Installer MVP limits:

- Max archive size: 64 MB.
- Max extracted size: 128 MB.
- Max files: 512.
- Max path length: 180.
- Path traversal, absolute paths, drive letters, and UNC-style paths are rejected.

`.pctrg` is not a sandbox. External Godot code can be unsafe.
