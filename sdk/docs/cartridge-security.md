# Cartridge Security

Trust levels:

- `built_in`: shipped with PopugVPocket.
- `trusted`: curated local source, checksum verified.
- `untrusted`: manually imported file.
- `blocked`: cannot launch.

External cartridges may contain unsafe code. Install only from trusted sources. Developer Mode is required for untrusted cartridges and downgrades.

Not implemented yet:

- Digital signatures.
- Sandbox for arbitrary GDScript.
- Runtime permission enforcement beyond manifest validation.
- Real network Store.
