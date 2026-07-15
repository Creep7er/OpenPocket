# OpenPocket

OpenPocket is an open-source pixel-art virtual handheld built with Godot 4.7. It combines an Android-first console shell, trusted built-in apps and games, and an experimental installable cartridge format.

**Project status:** Experimental / Alpha

**Current version:** 0.3.2

**First public source snapshot:** 0.3.2

![OpenPocket interface showing Home, Library, and Breakout](docs/screenshots/openpocket-hero.png)

## What Is OpenPocket?

OpenPocket presents a responsive handheld body around a pixel-perfect 400x320 virtual screen. The outer controls adapt to portrait phone screens, while Shell and cartridge content remain sharp and controller-driven.

Version 0.3.2 proves the local cartridge lifecycle. It is not a secure third-party code platform: external cartridges can execute Godot code in the application process.

## Highlights

- Responsive portrait layout with safe-area-aware margins.
- Pixel D-pad, A/B/X/Y buttons, MENU, and BACK controls.
- Keyboard, gamepad, touch, and Android Back integration through `PocketInput`.
- Package-scoped settings, save data, and cartridge audio ownership.
- `.pctrg` installation, inspection, checksum verification, update, and uninstall flows.
- Android Storage Access Framework picker without broad storage permissions.
- Local mock Store with Featured, All, Updates, and Search views.
- Experimental game/app SDK templates and cartridge builder.

## Screenshots

| Home | Library | Store |
| --- | --- | --- |
| ![Home](docs/screenshots/home.png) | ![Library](docs/screenshots/library.png) | ![Store](docs/screenshots/store.png) |

| Breakout | Install warning |
| --- | --- |
| ![Breakout](docs/screenshots/breakout.png) | ![Install cartridge](docs/screenshots/install-cartridge.png) |

## Built-In Cartridges

- **Snake:** Classic and Time Attack modes, configurable rules, high scores, and statistics.
- **Pocket Pong:** Player vs CPU with configurable difficulty, target score, and match settings.
- **Pocket Notes:** Short local notes edited with an on-screen pixel keyboard.

The repository also contains source and local Store fixtures for Breakout Mini, Pocket Dice, and Pixel Clock. They are examples, not remotely distributed packages.

## Cartridge System

A `.pctrg` file is a ZIP container with `cartridge.json`, `content.pck`, and optional metadata such as `README.md`, `LICENSE`, and `icon.png`. Built-in cartridges are trusted project source. External cartridges are installed into app-owned storage and may execute unsandboxed GDScript.

**Library** lists cartridges currently available to launch. **Store** reads `store/mock_catalog.json` and demonstrates discovery and installation from repository-local files; it has no network backend.

## Install A Cartridge

1. Open **Install Cartridge** from Home.
2. Select a `.pctrg` with Android Files or the desktop file dialog.
3. Review its identity, capabilities, and warning.
4. Enable Developer Mode for manually imported external code.
5. Confirm installation only when the source is trusted.

Checksums detect corruption. They do not prove publisher identity. See [SECURITY.md](SECURITY.md).

## Controls

| Console | Keyboard |
| --- | --- |
| D-pad | Arrow keys or WASD |
| A | Z |
| B | X |
| X | A |
| Y | S |
| MENU | Enter |
| BACK | Escape |

## Android Builds

The Android package id is `org.openpocket.app`; version 0.3.2 uses `versionCode` 5. The project provides development APK, compact debug APK, and unsigned AAB export presets. Prebuilt Android files will be attached to the Releases page after a public release is created.

The compact preset keeps arm64 and the SAF plugin while compressing the native Godot library. Production signing is not configured.

## Quick Start For Development

Requirements:

- Godot 4.7 stable without .NET.
- Python 3.10 or newer.
- Git.

```powershell
git clone https://github.com/Creep7er/OpenPocket.git
cd OpenPocket
godot --path .
```

Validate the source tree:

```powershell
python tools/validate_project.py
godot --headless --path . --editor --quit
godot --headless --path . res://tools/smoke_runner.tscn
```

The executable may be named `godot`, `godot4`, or a platform-specific Godot 4.7 binary.

## Build From Source

Desktop development only needs Godot. Android export additionally needs JDK 17, Android SDK platform 36, build-tools 35.0.1, Godot 4.7 export templates, and the included Android plugin build.

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_android_debug.ps1 `
  -Godot path\to\godot.exe `
  -JavaHome path\to\jdk `
  -AndroidHome path\to\android-sdk `
  -Preset "Android Compact Debug" `
  -Output exports\android\openpocket-0.3.2-compact-debug.apk
```

See [docs/android-build.md](docs/android-build.md) for setup details.

## Create A Cartridge

Start with `sdk/templates/cartridge-game` or `sdk/templates/cartridge-app`, then update both manifests and use only the public Pocket services.

```powershell
python tools/cartridge_builder.py build path\to\cartridge
python tools/cartridge_builder.py validate dist\cartridges\your.cartridge-0.1.0.pctrg
```

Guides live in [docs/cartridges](docs/cartridges/overview.md) and [sdk/docs](sdk/docs/creating-a-game.md). Standalone templates are also available in [openpocket-app-template](https://github.com/Creep7er/openpocket-app-template) and [openpocket-game-template](https://github.com/Creep7er/openpocket-game-template).

## Repository Structure

```text
app/          Runtime, Shell, responsive console UI
packages/     Trusted built-in cartridges
cartridges/   Source for external cartridge examples
store/        Local mock catalog and package fixtures
sdk/          Experimental API docs, schemas, and templates
docs/         Architecture, Android, cartridge, and release docs
tools/        Validators, builders, smoke tests, and capture tools
android/      OpenPocket Android plugin source and AAR
.github/      Issue templates and CI workflows
```

## Current Limitations

- External Godot code is not sandboxed or digitally signed.
- Developer Mode changes install policy; it does not make code safe.
- Store content is local and mock-only; there is no network provider in use.
- Mounted PCK files cannot be reliably unloaded, so some updates require restart.
- The cartridge API is experimental and has no long-term compatibility guarantee yet.
- AAB production signing and broad real-device coverage are not complete.

## Roadmap

See [ROADMAP.md](ROADMAP.md). The next priorities are stronger trust and permissions, SDK stabilization, compatibility validation, and broader Android testing.

## Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md), [ARCHITECTURE.md](ARCHITECTURE.md), and [AGENTS.md](AGENTS.md) before changing runtime or cartridge behavior.

A concise Russian overview is available at [docs/README.ru.md](docs/README.ru.md).

## License

OpenPocket is licensed under the [MIT License](LICENSE). Third-party and project-authored asset notices are listed in [THIRD_PARTY.md](THIRD_PARTY.md).
