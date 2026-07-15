# PocketStorage API

`PocketStorage` stores shell settings and package-scoped values.

Settings:

- `get_setting(key: String, fallback: Variant = null) -> Variant`
- `set_setting(key: String, value: Variant) -> void`
- `reset_settings() -> void`

Package data:

- `get_package_value(package_id: String, key: String, default_value: Variant = null) -> Variant`
- `set_package_value(package_id: String, key: String, value: Variant) -> void`
- `get_package_data(package_id: String, key: String, default_value: Variant = null) -> Variant`
- `set_package_data(package_id: String, key: String, value: Variant) -> bool`

Package settings:

- `get_package_setting(package_id: String, key: String, default_value: Variant = null) -> Variant`
- `set_package_setting(package_id: String, key: String, value: Variant) -> bool`
- `reset_package_settings(package_id: String) -> bool`

Packages must use their manifest id as `package_id`. They should not read or
write `FileAccess` directly for normal saves.

`get_package_value` and `set_package_value` are compatibility wrappers for
package data. Settings are resettable; data is intended for scores, statistics,
and user-created package content.
