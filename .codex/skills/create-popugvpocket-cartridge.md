# Create PopugVPocket Cartridge

Use this skill when adding a new PopugVPocket `.pctrg` cartridge.

1. Choose `game` or `app`.
2. Create a reverse-DNS package id, for example `org.example.timer`.
3. Copy `sdk/templates/cartridge-game` or `sdk/templates/cartridge-app`.
4. Rename paths and ids so resources live under one cartridge root.
5. Create or update `cartridge.json`.
6. Use only public PopugVPocket APIs: `PocketInput`, `PocketStorage`, `CartridgeAudio`, `CartridgeAchievements`, `PocketSystem`, and `PocketTheme`.
7. Add a project-authored `icon.png`.
8. Run `python tools/cartridge_builder.py build <cartridge-dir>`.
9. Run `python tools/cartridge_builder.py validate <pctrg>`.
10. Generate a catalog entry draft and submit it through catalog review.
11. Do not change runtime services unless the cartridge exposes a real SDK gap.
