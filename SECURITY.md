# Security Policy

OpenPocket 0.3.2 supports trusted built-in cartridges and experimental external cartridge installation. It is not a sandboxed third-party code platform.

## External Code Warning

External `.pctrg` files can contain a Godot PCK and GDScript that executes inside the OpenPocket process. Such code can potentially access Godot APIs beyond the documented Pocket services.

- Developer Mode permits manual installation; it does not make code safe.
- SHA-256 checksums verify integrity against expected metadata; they do not establish publisher identity or trust.
- Digital cartridge signatures and a trusted signing root are not implemented.
- The local mock Store is not a security boundary.
- Install external cartridges only from sources you trust.

## Installation And Android Permissions

The Android picker uses Storage Access Framework to let the user choose one file. The plugin copies that file into app-owned staging storage and does not request broad read, write, or manage-external-storage permissions.

Android INTERNET permission is disabled in the current export presets. The active Store provider reads repository-local metadata and files.

## Local Data

Shell settings and package-scoped settings/data are stored locally through Godot `user://`. Package data may include high scores, statistics, and notes. OpenPocket 0.3.2 does not provide cloud synchronization.

## Known Boundaries

- PCK resources cannot be reliably unloaded at runtime; replacing a mounted cartridge may require restart.
- Capability declarations are metadata and validation input, not an enforced process sandbox.
- `CartridgeAudio` owns supported cartridge sounds, but unsandboxed code can still call `AudioServer` directly.
- Production Android signing is not configured in the repository.

## Reporting A Vulnerability

Use a private security advisory after the public repository is created and private vulnerability reporting is enabled. Do not publish exploit details in a normal issue before a private reporting channel exists.

General bugs without security impact can use the repository bug report template.
