# AI Agent Guide

Read `AGENTS.md`, the manifest reference, and lifecycle docs before editing. Work only inside the cartridge repository. Preserve the unique `res://cartridges/<id>/` root and use only `PocketInput`, `PocketStorage`, `CartridgeAudio`, `PocketSystem`, and `PocketTheme`.

Forbidden: direct `Input`, direct `FileAccess`, shell internals, arbitrary resource roots, undeclared network access, default/non-pixel fonts, mouse-only navigation, and unrelated refactors.

## Ready Prompt

```text
Read AGENTS.md and docs/AI_AGENT_GUIDE.md.

Create an OpenPocket cartridge based on this template.

Concept:
[describe cartridge]

Requirements:
- preserve cartridge root and public APIs;
- use PocketInput;
- use package-scoped storage;
- controller-only navigation;
- pixel-art UI;
- update cartridge.json;
- run validation;
- build .pctrg;
- report output path.
```

## Checklist

- [ ] manifest valid
- [ ] unique resource root
- [ ] no direct Input
- [ ] no direct FileAccess
- [ ] controller-only navigation
- [ ] PixelFont
- [ ] package-scoped storage
- [ ] pause/resume
- [ ] exit flow
- [ ] builder passes
