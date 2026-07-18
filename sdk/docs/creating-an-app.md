# Creating an PopugVPocket App

PopugVPocket apps are Control scenes that run inside the 400x320 virtual screen.
They must be fully controllable with `PocketInput`; Android system keyboard input
cannot be the only input path.

1. Copy `sdk/templates/app` to `packages/apps/<name>`.
2. Edit `manifest.json` and keep `type` set to `app`.
3. Add the package path, for example `apps/<name>`, to `packages/index.json`.
4. Store app data with `PocketStorage.get_package_data()` and `set_package_data()`.
5. Run `python tools/validate_project.py`.

Apps should emit:

- `request_system_menu` when `PocketInput.MENU` is pressed.
- `exit_to_library` when the user backs out of the app.

Use `PixelFont` and `PocketTheme.palette()` for visible text and colors.
