# Project Structure

Keep source below one package root:

```text
cartridge/
  cartridge.json
  manifest.json
  main.tscn
  main.gd
  icon.png
  README.md
  LICENSE
```

The builder remaps this directory to `res://cartridges/<id>/`. Do not reference another cartridge root or OpenPocket shell internals.
