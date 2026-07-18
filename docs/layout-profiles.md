# Layout Profiles

Both profiles wrap the same `PocketScreen` 400x320 logical display. Cartridges never inspect the physical profile.

| Profile | Orientation | Composition |
| --- | --- | --- |
| VBoy | Portrait | Display above lower thumb-zone controls |
| VGirl | Landscape | Display left, controls in the right hardware zone |

The selected profile persists in `PocketStorage`. Android orientation changes only after explicit profile selection; desktop minimum window size follows the selected profile. Safe area comes from `DisplayServer.get_display_safe_area()` with small Android-only fallback insets.
