# AGENTS.md

Rules for AI-assisted work on OpenPocket:

- Read `ARCHITECTURE.md` and the relevant cartridge/SDK docs before changing behavior.
- Preserve public Pocket APIs unless the task explicitly includes a documented migration.
- Cartridge controls use `PocketInput`, not direct `Input`.
- Cartridge persistence uses `PocketStorage`, not direct `FileAccess`.
- Cartridge sound uses `CartridgeAudio`; never mutate global `AudioServer` state.
- Every built-in package has valid `manifest.json` and `cartridge.json` metadata and an entry in `packages/index.json`.
- Preserve controller-only navigation and Android Back behavior.
- Preserve the pixel visual language: hard edges, limited palettes, nearest filtering, and no standard Godot controls in the visible Shell.
- Do not add features without matching documentation and focused verification.
- Avoid unrelated refactors and keep the requested scope narrow.
- Never commit APK, AAB, SDK/JDK files, keystores, user data, logs, or generated staging output.
- Do not push or publish releases unless the user explicitly requests it.
- Run at least `python tools/validate_project.py`, plus the smallest relevant Godot checks.
