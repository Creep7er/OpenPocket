# Store Provider

The Store runtime uses a provider abstraction:

```gdscript
fetch_catalog()
fetch_details(cartridge_id)
download(cartridge_id, version)
search(query)
```

`LocalStoreProvider` is enabled by default and reads `res://store/mock_catalog.json`.

`HttpStoreProvider` is a disabled stub. OpenPocket does not request Android INTERNET permission for this MVP.
