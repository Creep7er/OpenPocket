# Changelog

This project follows the structure of [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). OpenPocket 0.3.2 is the first public source snapshot. Earlier versions were private development milestones reconstructed from source manifests and Git history; they were not public GitHub releases.

## [Unreleased]

## [0.4.0] - In development

### Added
- GitHub-hosted cartridge catalog provider with last-successful offline cache.
- Local cartridge achievements and Collection summary.
- Cartridge-provided themes/backgrounds and a permanent Reward Vault.
- Snake Master challenge and completion rewards.

### Changed
- Store distribution uses a public static GitHub catalog instead of a dedicated backend.
- Cartridge manifests support optional achievements and cosmetics.
- Uninstall keeps achievements and earned permanent rewards.

### Security
- Downloads require HTTPS release URLs and catalog SHA-256 verification.
- External Godot code remains unsandboxed; achievements are not anti-cheat protected.

## [0.3.2] - First public source snapshot

### Added

- Package-scoped `CartridgeAudio` ownership.
- Compact arm64 Android debug APK and unsigned AAB export presets.
- APK/AAB size analysis tooling.

### Changed

- Simplified Home, Library, Store, Settings, cartridge details, install confirmation, and system menus.
- Hid technical cartridge information behind Developer Mode.

### Fixed

- Store Featured, All, Updates, and Search filtering, including semantic version comparison.
- Breakout launch, menus, gameplay state, controls, collision handling, lives, and end states.
- Cartridge sound cleanup no longer stops Shell-owned audio.

### Security

- Kept external GDScript explicitly unsandboxed and unsigned.

### Build

- Set Android `versionName` 0.3.2 and `versionCode` 5.
- Added development APK, compact debug APK, and AAB build profiles.

## [0.3.1] - Internal development milestone

### Added

- Android SAF and desktop cartridge file pickers.
- Install confirmation, verification, update, management, and uninstall flows.
- Runnable PCK cartridge builder, example fixtures, standalone template generator, and development guides.

### Changed

- Moved external cartridge resources under unique package roots.
- Set Android `versionCode` 4.

### Security

- Required Developer Mode for manually imported external cartridges while documenting the lack of sandboxing.

## [0.3.0] - Internal development milestone

### Added

- `.pctrg` format, `CartridgeManager`, installer, registry, loader, and local Store provider.
- Cartridge Library/Store flows, manifests, builder tooling, templates, and security documentation.

### Changed

- Migrated Snake, Pocket Pong, and Pocket Notes metadata into the cartridge architecture.

## [0.2.0] - Internal development milestone

### Added

- Package-scoped settings and data APIs.
- Snake modes, settings, high scores, and statistics.
- Pocket Pong match settings and CPU difficulty.
- Pocket Notes and initial game/app SDK templates.

### Changed

- Expanded the built-in package index and package documentation.

## [0.1.0] - Internal development milestone

### Added

- Initial Shell with Home, Library, Settings, and About.
- `PocketInput`, `PocketStorage`, routing, Snake, Android debug export, and pixel console UI.
