# Cartridge Storage

Cartridges must use `PocketStorage` for persistent data.

Use package-scoped methods:

```gdscript
PocketStorage.get_package_data(PACKAGE_ID, "key", default_value)
PocketStorage.set_package_data(PACKAGE_ID, "key", value)
PocketStorage.get_package_setting(PACKAGE_ID, "key", default_value)
PocketStorage.set_package_setting(PACKAGE_ID, "key", value)
```

Uninstall defaults to removing the app only and preserving save data. Data deletion requires a separate explicit action.
