# Installing Cartridges

OpenPocket installs cartridges into:

```text
user://cartridges/packages/<cartridge-id>/
```

Install flow:

1. Choose `Install Cartridge` and select `.pctrg` with Android Files or the desktop native file dialog.
2. Copy it to app-owned staging and inspect `cartridge.json`.
3. Verify limits, PCK header, runtime compatibility, capabilities, and SHA-256.
4. Show identity, trust, and capability warnings.
5. Confirm and atomically install through staging.
6. Register in `user://cartridges/installed.json`.

Android uses Storage Access Framework without broad storage permissions. `user://imports/` remains a developer-only fallback.
