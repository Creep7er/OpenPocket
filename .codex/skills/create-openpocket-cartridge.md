# Create OpenPocket Cartridge

Use this skill when adding a new OpenPocket `.pctrg` cartridge.

1. Choose `game` or `app`.
2. Create a reverse-DNS package id, for example `org.example.timer`.
3. Copy `sdk/templates/cartridge-game` or `sdk/templates/cartridge-app`.
4. Rename paths and ids so resources live under one cartridge root.
5. Create or update `cartridge.json`.
6. Use only public OpenPocket APIs: `PocketInput`, `PocketStorage`, `CartridgeAudio`, `PocketSystem`, and `PocketTheme`.
7. Add a small placeholder `icon.png` or let `tools/cartridge_builder.py` inject the deterministic placeholder.
8. Run `python tools/cartridge_builder.py build <cartridge-dir>`.
9. Run `python tools/cartridge_builder.py validate <pctrg>`.
10. Add the cartridge to `store/mock_catalog.json` only when the user asks for local Store visibility.
11. Do not change runtime services unless the cartridge exposes a real SDK gap.
