# Store Provider

The Store runtime uses a provider abstraction:

```gdscript
fetch_catalog()
fetch_details(cartridge_id)
download(cartridge_id, version)
search(query)
```

`GitHubCatalogProvider` is enabled by default and reads the static public `catalog.json` over HTTPS with a last-successful cache. `LocalStoreProvider` remains a development fixture.

OpenPocket requests Android INTERNET only for catalog and release asset GET requests. Downloads remain subject to SHA-256 and installer validation.
