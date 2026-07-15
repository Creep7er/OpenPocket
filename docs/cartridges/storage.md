# Storage

Use `PocketStorage.get_package_setting` and `set_package_setting` for preferences. Use `get_package_data` and `set_package_data` for records, user content, and statistics. Always pass your package id.

Do not use `FileAccess`. App-only uninstall preserves both namespaces; app-and-data uninstall clears both.
