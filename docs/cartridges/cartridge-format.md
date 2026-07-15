# Cartridge Format

`.pctrg` is a ZIP container with safe relative entry names. Required files are `cartridge.json` and `content.pck`; `icon.png`, `README.md`, and `LICENSE` are recommended.

The content file must be a Godot PCK with `GDPC` header. Its SHA-256 must equal `content.sha256`. Runtime limits are 64 MB archive size, 128 MB extracted size, 512 files, path depth 12, and path length 180.
