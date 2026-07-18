# Contributing

Thank you for helping improve OpenPocket. SDK 0.4.0 is experimental, so focused changes with explicit tests and documentation are especially valuable.

## Requirements

- Godot 4.7 stable without .NET.
- Python 3.10 or newer.
- Git.
- JDK 17 and Android SDK only for Android exports.

## Setup And Checks

```powershell
git clone https://github.com/Creep7er/OpenPocket.git
cd OpenPocket
godot --path .
python tools/validate_project.py
godot --headless --path . --editor --quit
godot --headless --path . res://tools/smoke_runner.tscn
```

Use the executable name or absolute path appropriate for your installation. A project-local `.tools` directory is optional and is not required by the source tree.

For a compact Android build:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_android_debug.ps1 `
  -Godot path\to\godot.exe `
  -JavaHome path\to\jdk `
  -AndroidHome path\to\android-sdk `
  -Preset "Android Compact Debug" `
  -Output exports\android\openpocket-0.4.0-compact-debug.apk
```

## Runtime And UI Conventions

- Read `ARCHITECTURE.md` before changing runtime, loading, or storage behavior.
- Preserve controller-only navigation with D-pad, A/B/X/Y, MENU, and BACK.
- Keep the visible Shell pixel-based: hard edges, limited palettes, nearest filtering, and no standard Godot controls.
- Avoid unrelated refactors and document public API or behavior changes.

## Cartridge Development

- Include valid `manifest.json` and `cartridge.json` files.
- Add trusted built-ins to `packages/index.json`.
- Use `PocketInput`, never direct `Input`, for cartridge controls.
- Use `PocketStorage`, never direct `FileAccess`, for normal cartridge state.
- Use `CartridgeAudio`; do not change global `AudioServer` state.
- Use `PocketTheme` for palette-compatible rendering.
- Document controls, storage keys, capabilities, lifecycle behavior, and asset licensing.

Build and validate archives with:

```powershell
python tools/cartridge_builder.py build path\to\cartridge
python tools/cartridge_builder.py validate path\to\cartridge.pctrg
```

## Assets And Licenses

Only add assets whose source and license are known and compatible with the project. Update `THIRD_PARTY.md` or the package README when an asset is not project-authored.

## Pull Request Checklist

- [ ] The change is focused and does not expand scope unnecessarily.
- [ ] `python tools/validate_project.py` passes.
- [ ] Godot headless import and relevant smoke tests pass.
- [ ] Runtime/API/package changes have documentation updates.
- [ ] Cartridge code avoids direct `Input`, `FileAccess`, and global audio mutation.
- [ ] Manifests and `packages/index.json` are updated where required.
- [ ] Controller-only and touch behavior are checked for UI changes.
- [ ] New assets have documented licensing.
- [ ] No generated artifacts, credentials, or local paths are committed.
