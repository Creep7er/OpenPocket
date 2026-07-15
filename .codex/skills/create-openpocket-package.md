# Create OpenPocket Package

Use this skill when creating a new built-in OpenPocket package.

1. Choose `game` or `app`.
2. Copy `sdk/templates/game` or `sdk/templates/app` into `packages/games/<name>` or `packages/apps/<name>`.
3. Update `manifest.json` with a unique reverse-DNS id, package name, author, and `sdk_version`.
4. Implement the package using only `PocketInput`, `PocketStorage`, `CartridgeAudio`, `PocketSystem`, and `PocketTheme`.
5. Add the package path to `packages/index.json`.
6. Run `python tools/validate_project.py`.
7. Run a Godot headless editor import.
8. Run the smoke check if it is stable on the current Godot build.
9. Do not change runtime code unless the package exposes a missing public API requirement.
