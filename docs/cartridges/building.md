# Building

Use Godot 4.7 and Python 3:

```powershell
python tools/cartridge_builder.py build cartridges/source/org.example.app
python tools/cartridge_builder.py validate dist/cartridges/org.example.app-1.0.0.pctrg
python tools/cartridge_builder.py inspect dist/cartridges/org.example.app-1.0.0.pctrg
```

The builder creates a temporary Godot project and calls `--export-pack`. A renamed ZIP is not accepted as PCK content.
