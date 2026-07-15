# Debugging

Run the sample in its template project, validate JSON, build, inspect, and install in Developer Mode. Typical failures are an incorrect package id, an entry path outside the unique root, direct forbidden APIs, a missing scene, an unsupported capability, or a stale checksum.

For Android, capture process-scoped logcat and check `PocketFilePicker`, `CartridgeManager`, and resource load messages.
