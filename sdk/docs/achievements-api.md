# Achievements API

SDK 0.5.0 exposes experimental `CartridgeAchievements.emit_event`, `increment`, and `set_value`. Event names must match optional definitions in `cartridge.json`; runtime scopes every update to the active cartridge ID. Cartridges must not read or write `user://profile/achievements.json`.

Supported types are `event`, `counter`, and `value`; comparisons are `gte`, `lte`, and `eq`. There is no expression language, online validation, leaderboard, or anti-cheat guarantee.
