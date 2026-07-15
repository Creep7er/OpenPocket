# Creating a Game

OpenPocket MVP games are Godot scenes packaged with a `manifest.json`.

## Minimal Layout

```text
packages/games/my_game/
  manifest.json
  main.tscn
  main.gd
```

You can copy `sdk/templates/game` as a starting point.

## Manifest

Required fields:

- `id`: unique reverse-DNS package id.
- `name`: display name.
- `version`: package version.
- `type`: `game` for games.
- `entry_scene`: scene path relative to the package folder.
- `sdk_version`: OpenPocket SDK version.
- `author`: author name.

## Input

Use `PocketInput` instead of UI nodes:

```gdscript
if PocketInput.just_pressed(PocketInput.A):
    start()
if PocketInput.is_pressed(PocketInput.LEFT):
    move_left()
```

Buttons: `UP`, `DOWN`, `LEFT`, `RIGHT`, `A`, `B`, `X`, `Y`, `MENU`, `EXIT`.

## System Menu

Games should emit a signal such as `request_system_menu` when `MENU` is pressed. The shell will show the overlay.

## Storage

Use `PocketStorage` for simple local values:

```gdscript
PocketStorage.set_setting("my_game_high_score", score)
var high_score := int(PocketStorage.get_setting("my_game_high_score", 0))
```

For package-scoped saves, prefer:

```gdscript
PocketStorage.set_package_data("org.example.game", "high_score", score)
var high_score := int(PocketStorage.get_package_data("org.example.game", "high_score", 0))
PocketStorage.set_package_setting("org.example.game", "difficulty", "normal")
```

## Returning to Shell

Expose and emit an `exit_to_library` signal when the game wants to return to Library.

## MVP Limits

- External untrusted packages are not loaded dynamically yet.
- No package signing or permission model exists in the MVP.
- Network access is not part of the MVP.
