# AGENTS.md

Rules for AI-assisted work on PopugVPocket:

- Product identity is PopugVPocket by Popugonet; cartridges use format v2 and `.pctrg`.
- Official built-ins use `org.popugonet.popugvpocket.*`; templates must use an obvious example namespace.

- Read `ARCHITECTURE.md` and the relevant cartridge/SDK docs before changing behavior.
- Preserve public Pocket APIs unless the task explicitly includes a documented migration.
- Cartridge controls use `PocketInput`, not direct `Input`.
- Cartridge persistence uses `PocketStorage`, not direct `FileAccess`.
- Cartridge sound uses `CartridgeAudio`; never mutate global `AudioServer` state.
- Cartridge achievements use `CartridgeAchievements`; never edit profile files directly.
- Cartridge cosmetics are data-only and use safe relative paths; never accept cartridge shaders or cosmetic scripts.
- Catalog entries use HTTPS release assets and SHA-256; catalog inclusion is not a sandbox.
- Every built-in package has valid `manifest.json` and `cartridge.json` metadata and an entry in `packages/index.json`.
- Preserve controller-only navigation and Android Back behavior.
- VBoy/VGirl are physical profiles; cartridge content always targets `PocketScreen` 400x320.
- Preserve the pixel visual language: hard edges, limited palettes, nearest filtering, and no standard Godot controls in the visible Shell.
- Do not add features without matching documentation and focused verification.
- Avoid unrelated refactors and keep the requested scope narrow.
- Never commit APK, AAB, SDK/JDK files, keystores, user data, logs, or generated staging output.
- Do not push or publish releases unless the user explicitly requests it.
- Run at least `python tools/validate_project.py`, plus the smallest relevant Godot checks.
