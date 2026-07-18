# PopugVPocket Architecture

PopugVPocket 0.5.0 separates profile-driven handheld hardware, pixel-perfect content, runtime services, trusted built-ins, a moderated static catalog, local profile data, and the experimental external cartridge pipeline.

```mermaid
flowchart TD
    Android["Android or desktop window"] --> Frame["Responsive ConsoleFrame"]
    Frame --> Display["400x320 SubViewport"]
    Frame --> Profiles["ConsoleLayoutManager: VBoy / VGirl"]
    Profiles --> Touch["D-pad or pixel stick and action controls"]
    Display --> Shell["Shell routes and overlays"]
    Shell --> Manager["CartridgeManager"]
    Shell --> Store["StoreService"]
    Manager --> Builtins["Built-in packages/index.json"]
    Manager --> Installer["Installer and registry"]
    Installer --> External["External PCK cartridges"]
    Touch --> Input["PocketInput"]
    Builtins --> APIs["PocketStorage / CartridgeAudio / PocketTheme"]
    External --> APIs
    Picker["Desktop dialog or Android SAF"] --> Installer
    Store --> GitHub["GitHub raw catalog + release assets"]
    Store --> Cache["Last successful local cache"]
    APIs --> Achievements["Local achievement profile"]
    Achievements --> Vault["Permanent Reward Vault"]
```

## Shell And Display

`app/main.gd` owns routing, the active cartridge, the system overlay, Android Back handling, and package launch. `app/shell/shell_view.gd` provides Home, Library, Store, install, Settings, and About flows. `app/shell/system_menu.gd` provides pause, restart, package settings, Library, Home, and confirmed application exit.

`app/ui/console_frame.gd` fills the available window, applies Android safe-area margins, and lays out the physical controls responsively. Shell and cartridge scenes render into a separate 400x320 `SubViewport` using nearest-neighbor filtering. Integer scaling is limited to the virtual display rather than the whole phone layout.

`ConsoleLayoutManager` selects VBoy portrait or VGirl landscape and persists the choice. VBoy stacks the display above its lower controls; VGirl uses independent left-direction, center-display, and right-action zones with MENU/BACK below the display. `PocketScreen` owns the invariant 400x320 logical display. Physical controls map through `PocketInput`, so cartridges never know the active profile or whether directions came from a D-pad, fixed stick, or floating stick.

## Runtime Services

- `PocketInput`: keyboard, gamepad, Android Back, and virtual console input.
- `PocketStorage`: Shell settings and package-scoped settings/data under Godot `user://`.
- `PocketAudio`: Shell-owned UI tones that honor global sound settings.
- `CartridgeAudio`: active-package sound ownership and cleanup.
- `PocketSystem`: notifications, platform context, and confirmed application exit.
- `PocketTheme`: active palette and pixel display constants.
- `PocketRouter`: Shell route and system-menu requests.
- `CartridgeManager`: built-in bootstrap, external registry, verification, mounting, launch preparation, and removal.
- `PocketFilePicker`: desktop file dialog plus Android SAF bridge, both producing an app-owned staging file.
- `StoreService`: filtering, semantic version comparison, and download handoff through a provider.
- `PocketPackages`: compatibility adapter over `CartridgeManager`; retained for older Shell/runtime call sites and considered deprecated for new cartridge code.

## Built-In And External Cartridges

Trusted built-ins are listed in `packages/index.json` and carry both legacy-compatible `manifest.json` and cartridge metadata. Runtime directory scanning is avoided so exported projects have deterministic contents.

External `.pctrg` files contain `cartridge.json` and a real Godot `content.pck`. They install under `user://cartridges/packages/`; registry metadata and app-owned import staging stay under `user://`. Mounted resources use `res://cartridges/<package-id>/` and cannot replace existing resources.

Godot does not provide dependable runtime PCK unloading. Updating or removing a mounted cartridge can therefore require an application restart.

## Storage And Lifecycle

Each package has separate `settings` and `data` namespaces. Settings are resettable preferences. Data holds high scores, statistics, and user-created content. `get_package_value` and `set_package_value` remain compatibility aliases for package data.

Library launch prepares a package through `CartridgeManager`, opens a `CartridgeAudio` scope, then instantiates its entry scene inside the virtual display. MENU opens the Shell overlay. BACK follows package or Shell navigation. Exiting the package ends its audio scope and returns ownership to the Shell.

## Store Provider

PopugVPocket 0.5.0 uses `GitHubCatalogProvider` with catalog schema v2, approved-only entries, ETag/Last-Modified revalidation, request limits, and last-successful cache. `LocalStoreProvider` remains a development fixture. Downloaded release assets are checked against catalog SHA-256 before installer validation. Android INTERNET is used only for catalog and asset GET requests.

## Achievements And Cosmetics

`CartridgeAchievements` binds event/counter/value updates to the active cartridge ID. `AchievementManager` owns versioned atomic profile storage; cartridges cannot select another namespace. Cartridge-provided themes/backgrounds are discovered from installed manifests. Permanent reward assets are copied into `user://profile/cosmetics/` with checksums and metadata, so uninstalling the source cartridge does not break earned rewards. These local records are user-editable and are not anti-cheat evidence.

## Android File Picker

The PopugVPocket Android plugin invokes Storage Access Framework. The user selects one `.pctrg`; the plugin copies it to app-owned storage and does not request broad storage access. Desktop builds use Godot `FileDialog` with the same installer handoff.

## Security Boundary

Built-ins are trusted because they ship with the source and application. External GDScript executes in the PopugVPocket process and is not sandboxed. Developer Mode is an explicit risk gate, not isolation. Checksums validate expected bytes, not publisher identity. Capability declarations are not a process-level permission boundary.

Future work may add signed manifests, trust roots, permissions, storage quotas, and an isolated scripting runtime such as constrained Lua or WebAssembly. None of those controls are implemented in 0.5.0.

## Compatibility Reset

Format v2 intentionally rejects OpenPocket format v1 cartridges. The new Android package id has a separate sandbox, so no automatic old `user://` migration is claimed. A Developer Tools flow can import whitelisted JSON from a manually selected legacy ZIP after backing up current data; executable files and old cartridges are skipped.
