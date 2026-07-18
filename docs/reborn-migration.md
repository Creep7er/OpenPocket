# Reborn Migration

PopugVPocket 0.5.0 is a clean rebirth of OpenPocket. OpenPocket 0.3.2 was the final release under the old name. Because the project had no public user base, 0.5.0 intentionally resets cartridge and application compatibility.

The Android package id changed, so PopugVPocket cannot automatically read the private `user://` sandbox of the old application. The two apps may coexist. Keep the old app until any desired backup has been created.

Developer Mode exposes **Import Legacy OpenPocket Backup**. The importer accepts a manually selected ZIP, backs up current data, maps known package ids, and imports only whitelisted JSON settings/profile data. GDScript, PCK, PCTRG, binaries, and unknown entries are skipped. Format v1 cartridges must be rebuilt with the PopugVPocket SDK and format v2.
