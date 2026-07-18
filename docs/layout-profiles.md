# Layout Profiles

Both profiles wrap the same `PocketScreen` 400x320 logical display. Cartridges never inspect the physical profile.

| Profile | Orientation | Composition |
| --- | --- | --- |
| VBoy | Portrait | Display above lower thumb-zone controls |
| VGirl | Landscape | Directions left, centered display, action buttons right |

The selected profile persists in `PocketStorage`. Android orientation changes only after explicit profile selection; desktop minimum window size follows the selected profile. Safe area comes from `DisplayServer.get_display_safe_area()` with small Android-only fallback insets.

VGirl uses three independent horizontal zones. The D-pad or stick is centered in the left thumb zone, the 400x320 display keeps its aspect ratio in the middle, and `ActionClusterLayout` chooses a compact or diamond XYAB arrangement in the right thumb zone. MENU and BACK sit below the display.

The earlier landscape layout limited the entire console from height and assigned the screen a fixed 48 percent width. On short displays this reduced the screen and controls together and produced overlapping button minimum sizes. Version 0.5.1 calculates shell geometry, PocketScreen scale, and logical UI text scale separately. PocketScreen uses the largest integer display scale that fits, with fractional nearest scaling only when the physical window is smaller than 400x320.

Run `res://tools/vgirl_layout_audit.tscn` for the nine supported landscape previews. `res://tools/layout_preview.tscn -- --profile=vgirl --route=store --size=852x393 --debug=true` captures an actual runtime frame with optional safe-area and touch-zone bounds.
