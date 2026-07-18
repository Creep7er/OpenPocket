# Layout Profiles

Both profiles wrap the same `PocketScreen` 400x320 logical display. Cartridges never inspect the physical profile.

| Profile | Orientation | Composition |
| --- | --- | --- |
| VBoy | Portrait | Display above lower thumb-zone controls |
| VGirl | Landscape | Directions left, centered display, action buttons right |

The selected profile persists in `PocketStorage`. Android orientation changes only after explicit profile selection; desktop minimum window size follows the selected profile. Safe area comes from `DisplayServer.get_display_safe_area()` with small Android-only fallback insets.

VGirl uses three independent horizontal zones. The D-pad or stick is centered in the left thumb zone, the 400x320 display keeps its aspect ratio in the middle, and `ActionClusterLayout` always places four equal-size buttons as a plus in the right thumb zone: X above, Y left, A right, and B below. MENU and BACK sit below the display.

The earlier landscape layout limited the entire console from height and assigned the screen a fixed width. A first 0.5.1 pass still rounded every scale above 1 down to an integer, leaving a 400x320 display inside common 960x540 and 1280x720 windows. VGirl now calculates shell geometry, PocketScreen scale, and logical UI text scale separately, then chooses the largest one-eighth nearest-neighbor display step that fits. Shell lists, values, and footer hints use bitmap text scale 2 in VGirl; cartridge gameplay keeps its 400x320 contract. On a 1280x720 window the D-pad target reaches 260x260 and the equal-size plus action cluster exceeds 290x290. The layout audit enforces these text/control sizes and rejects a screen below 45 percent of the console width in addition to checking overlap.

Run `res://tools/vgirl_layout_audit.tscn` for the nine supported landscape previews. `res://tools/layout_preview.tscn -- --profile=vgirl --route=store --size=852x393 --debug=true` captures an actual runtime frame with optional safe-area and touch-zone bounds.
