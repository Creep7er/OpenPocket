## Summary

<!-- Explain the user-visible or developer-visible change. -->

## Verification

<!-- List exact commands and relevant manual checks. -->

## Checklist

- [ ] The change is focused and avoids unrelated refactoring.
- [ ] `python tools/validate_project.py` passes.
- [ ] Godot headless import and relevant smoke tests pass.
- [ ] Runtime/API/package changes include documentation updates.
- [ ] Cartridge code avoids direct `Input`, `FileAccess`, and global `AudioServer` mutation.
- [ ] Manifests and `packages/index.json` are updated where required.
- [ ] Controller-only and touch behavior are preserved.
- [ ] New assets have documented sources and compatible licenses.
- [ ] No generated artifacts, local paths, or credentials are committed.
