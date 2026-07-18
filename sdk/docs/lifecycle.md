# Package Lifecycle

OpenPocket packages are loaded from manifests listed in `packages/index.json`.

Expected package signals:

- `request_system_menu`
- `exit_to_library`

The Shell owns package launch, pause overlay, routing, and application exit.
Packages should keep their own state inside the scene and use `PocketStorage`
for persistent values.

Android Back is handled by the runtime:

1. Close an open system overlay.
2. Pause or leave a running package through the runtime flow.
3. Navigate back inside Shell routes.
4. On Home, ask for exit confirmation.
5. Quit only after confirmation.

API `0.4.0` is experimental and may change before a stable release.
