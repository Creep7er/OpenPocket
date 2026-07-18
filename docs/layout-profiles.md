# Layout Profiles

Both profiles wrap the same `PocketScreen` 400x320 logical display. Cartridges never inspect the physical profile.

| Profile | Orientation | Composition |
| --- | --- | --- |
| VBoy | Portrait | Display above lower thumb-zone controls |
| VGirl | Landscape | Directions left, centered display, action buttons right |

The selected profile persists in `PocketStorage`. Android orientation changes only after explicit profile selection; desktop minimum window size follows the selected profile. Safe area comes from `DisplayServer.get_display_safe_area()` with small Android-only fallback insets.

VGirl uses three independent horizontal zones. The D-pad or stick is centered in the left thumb zone, the 400x320 display keeps its aspect ratio in the middle, and the XYAB diamond is centered in the right thumb zone. MENU and BACK sit below the display. The landscape body may grow taller than VBoy's width cap so controls remain usable without crowding on short, wide phone screens.
