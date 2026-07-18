# Manifest Reference

Required fields: `format_version`, `id`, `name`, `version`, `type`, `entry_scene`, `sdk_version`, `runtime`, `author`, `description`, and `content`.

- `id`: lowercase reverse-DNS id.
- `type`: `app` or `game` in runtime 0.4.0.
- `entry_scene`: `res://cartridges/<id>/main.tscn` or another scene under that exact root.
- `runtime`: minimum and optional maximum compatible runtime versions.
- `capabilities`: subset of `storage`, `audio`, `theme`, and `system_menu`.
- `content`: file must be `content.pck`; SHA-256 is filled by the builder.
- `achievements`: optional event/counter/value definitions scoped by cartridge id.
- `cosmetics`: optional data-only provided cosmetics and permanent reward definitions.
- `signature`: `null` in 0.4.0; signatures are not implemented.
