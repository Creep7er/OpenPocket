# Privacy

PopugVPocket 0.5.1 has no accounts, analytics, advertising identifiers, telemetry, or cloud synchronization.

- Achievements, rewards, settings, saves, and notes stay in local Godot `user://` storage.
- Store refresh downloads the public catalog from GitHub over HTTPS. GitHub can observe ordinary request metadata such as IP address and user agent.
- Cartridge release assets are downloaded only after a user install action.
- PopugVPocket does not upload the installed cartridge list; update comparison is local.
- Catalog refresh and optional cartridge downloads make ordinary HTTPS requests to GitHub. GitHub receives normal request metadata; PopugVPocket sends no profile or save contents.
- Application release checks are documented but are not automatically performed by the 0.5.1 runtime.

External unsandboxed cartridges may behave differently and should be installed only from sources the user trusts.
