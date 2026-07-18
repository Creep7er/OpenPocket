# Cartridge Store

The Store has three distinct update paths:

- **Application updates** are GitHub Release APK/AAB artifacts. Version 0.5.1 does not automatically download or install APKs.
- **Cartridge updates** compare installed and approved catalog versions, then download, verify, and replace cartridge files while preserving package storage, achievements, and permanent rewards.
- **Catalog updates** refresh the static GitHub `catalog.json` and fall back to the last valid local cache.

## Download lifecycle

Only one Store download runs at a time. Jobs move through queued, connecting, downloading, verifying, ready, installing, completed, failed, or cancelled states. HTTPS host validation, redirect and timeout limits, a 64 MiB cap, `.part` staging, catalog SHA-256, and atomic rename run before installer inspection.

## Manage lifecycle

Store details offer install, update, or reinstall as appropriate. Library marks missing or mismatched installs as `BROKEN`; Manage can repair from the current catalog entry. Uninstall may keep or remove package settings/data. Achievements and permanent rewards remain, while unavailable provided cosmetics fall back to built-in choices.

The public catalog currently has no approved external release assets. Pixel Clock and Pocket Dice are tested through local fixtures and remain pending until real GitHub Releases are published and moderated.
