# Pocket Pong

Single-player Pong for OpenPocket.

## Controls

- D-pad Up/Down: move left paddle.
- A: select menu item.
- B/BACK: return to the previous package screen or Library.
- MENU: system overlay.

## Mode

- Player vs CPU.

Two-player mode is not implemented because the current Pocket input map exposes one shared virtual controller.

## Settings

- CPU: Easy, Normal, Hard.
- Target: 5, 7, or 11.
- Ball: Slow, Normal, Fast.
- Paddle: Small, Normal, Large.
- Serve: Alternate or Random.

Settings apply to the next match.

## Storage Keys

Settings use `PocketStorage.get_package_setting("org.openpocket.pong", key, default)`.

Data keys:

- `statistics`

## Public APIs Used

- `PocketInput`
- `PocketStorage`
- `CartridgeAudio`
- `PocketTheme`

## Files

- `main.gd`: package UI and gameplay.
- `pong_config.gd`: match settings.
- `pong_rules.gd`: ball and match helpers.
- `pong_cpu_controller.gd`: CPU paddle tracking.
- `pong_statistics.gd`: statistics update helper.

## Known Limits

Physics and CPU difficulty are MVP-level and not playtested on real Android hardware.

## Assets

Project-authored code and visuals under the repository MIT license.
