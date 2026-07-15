# Roadmap

OpenPocket does not promise release dates. This roadmap separates current behavior from planned platform work.

## Current: 0.3.2

- Responsive Android-first Shell and pixel-perfect virtual screen.
- Trusted built-in Snake, Pocket Pong, and Pocket Notes cartridges.
- Experimental `.pctrg` installer, local mock Store, and cartridge SDK.
- Package-scoped storage and audio ownership.
- Compact debug APK and unsigned AAB export presets.

## Next: 0.4

- Design cartridge signatures and a stronger permission model.
- Replace or extend the local Store provider without presenting it as a security boundary.
- Stabilize the SDK surface and package compatibility validation.
- Expand real-device Android testing.
- Improve accessibility and localization.

## Later: 1.0

- Stable cartridge API and documented compatibility policy.
- Secure, reviewable distribution model for third-party cartridges.
- Production Android release and signing pipeline.

See [SECURITY.md](SECURITY.md) for the current trust limitations and [ARCHITECTURE.md](ARCHITECTURE.md) for possible isolation approaches.
