# Privacy

PopugVPocket 0.5.0 has no accounts, analytics, advertising identifiers, telemetry, or cloud synchronization.

- Achievements, rewards, settings, saves, and notes stay in local Godot `user://` storage.
- Store refresh downloads the public catalog from GitHub over HTTPS. GitHub can observe ordinary request metadata such as IP address and user agent.
- Cartridge release assets are downloaded only after a user install action.
- PopugVPocket does not upload the installed cartridge list; update comparison is local.

External unsandboxed cartridges may behave differently and should be installed only from sources the user trusts.
