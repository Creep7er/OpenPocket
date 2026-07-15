# Snake

Classic Snake for OpenPocket.

## Controls

- D-pad: turn.
- A: select menu item.
- B/BACK: return to the previous package screen or Library.
- MENU: system overlay.

## Modes

- Classic: play until collision.
- Time Attack: 60 seconds to score as much as possible; collision ends the run.

## Settings

- Difficulty: Easy, Normal, Hard, Extreme.
- Walls: Solid or Wrap.
- Growth: 1, 2, or 3 segments per food.
- Food: Classic or Timed.
- Grid: Small, Normal, Large.
- Obstacles: Off, Low, High.

Settings apply to the next game.

## Storage Keys

Settings use `PocketStorage.get_package_setting("org.openpocket.snake", key, default)`.

Data keys:

- `high_score.<mode>.<difficulty>`
- `statistics`

## Public APIs Used

- `PocketInput`
- `PocketStorage`
- `CartridgeAudio`
- `PocketTheme`

## Files

- `main.gd`: package UI and gameplay.
- `snake_config.gd`: settings and score config.
- `snake_rules.gd`: small movement helpers.
- `snake_statistics.gd`: statistics update helper.

## Known Limits

Balance has not been tuned on real Android hardware.

## Assets

Project-authored code and visuals under the repository MIT license.
