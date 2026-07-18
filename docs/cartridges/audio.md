# Audio

Use `CartridgeAudio.play_ui(event_name)` and `CartridgeAudio.play_sfx(stream_id)`.
PopugVPocket owns the player pool and stops only the active cartridge scope on
exit. A package-local `sound` setting never changes Shell or another cartridge.

`PocketAudio` is reserved for Shell UI. Do not access `AudioServer`, global
buses, or another package's players. External code is not sandboxed, so this is
not a security boundary. Do not bundle assets with unclear licenses.
