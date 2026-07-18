# PocketAudio API

PopugVPocket SDK 0.5.0 separates Shell audio from cartridge audio.

Events:

- `boot`
- `focus`
- `select`
- `back`
- `error`
- `pause`

Shell methods:

- `play(event_name: String) -> void`
- `play_ui_safe(event_name: String) -> bool`
- `is_available() -> bool`

Cartridges should use `CartridgeAudio`:

- `play_ui(event_name: String) -> bool`
- `play_sfx(stream_id: String) -> bool`
- `stop_own_sounds() -> void`
- `set_local_volume(value: float) -> void`

The runtime creates one audio scope for the active cartridge and destroys only
that scope on exit. Package setting `sound` mutes only that cartridge. Global
`sound_enabled` and `volume` still apply to every scope.

Cartridges must not access `AudioServer`, the Master bus, or Shell players.
External GDScript is not sandboxed, so this rule is an API contract rather than
a security boundary.

The service honors `PocketStorage` settings `sound_enabled` and `volume`.
Current sounds are generated locally at runtime, so no third-party assets are
bundled.
