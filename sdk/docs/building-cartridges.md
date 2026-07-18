# Building Cartridges

Build a cartridge:

```powershell
python tools\cartridge_builder.py build packages\games\snake
```

Validate:

```powershell
python tools\cartridge_builder.py validate dist\cartridges\org.popugonet.popugvpocket.snake-0.3.0-dev.pctrg
```

Inspect:

```powershell
python tools\cartridge_builder.py inspect dist\cartridges\org.popugonet.popugvpocket.snake-0.3.0-dev.pctrg
```

Generate the local mock Store catalog:

```powershell
python tools\cartridge_catalog.py build dist\cartridges
```

The current builder creates deterministic cartridge archives for MVP testing. Package-specific Godot PCK export is still experimental.
