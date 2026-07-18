# Cartridge Lifecycle

Built-in cartridges are registered during runtime bootstrap and appear in Library automatically.

External cartridges follow:

```text
inspect -> validate -> install -> registry -> details -> launch
```

Launch prepares the cartridge context:

```gdscript
{
  "id": "org.popugonet.popugvpocket.snake",
  "version": "0.3.0-dev",
  "trust": "built_in",
  "capabilities": ["storage", "audio", "theme", "system_menu"]
}
```

Packages should expose `exit_to_library`, `request_system_menu`, and optional pause/resume methods.
