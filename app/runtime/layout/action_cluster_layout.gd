extends RefCounted
class_name ActionClusterLayout

const MODE_DIAMOND := "diamond"
const MODE_COMPACT := "compact"


static func calculate(zone: Rect2, primary_visual: float, secondary_visual: float, minimum_touch: float, touch_pad: float) -> Dictionary:
	var primary_touch: float = floor(maxf(minimum_touch, primary_visual + touch_pad))
	var secondary_touch: float = floor(maxf(minimum_touch, secondary_visual + touch_pad))
	var required_spacing: float = floor(maxf(primary_touch, (primary_touch + secondary_touch) * 0.5) + 4.0)
	var diamond_extent: float = required_spacing * 2.0 + primary_touch
	var result: Dictionary = {}
	if zone.size.x >= diamond_extent and zone.size.y >= diamond_extent:
		var center := zone.get_center().floor()
		result = {
			"mode": MODE_DIAMOND,
			"X": _touch_rect(center + Vector2(0, -required_spacing), secondary_touch),
			"Y": _touch_rect(center + Vector2(-required_spacing, 0), secondary_touch),
			"A": _touch_rect(center + Vector2(required_spacing, 0), primary_touch),
			"B": _touch_rect(center + Vector2(0, required_spacing), primary_touch),
		}
	else:
		var gap: float = 4.0
		primary_touch = maxf(minimum_touch, primary_visual)
		secondary_touch = maxf(minimum_touch, secondary_visual)
		var cell: float = maxf(primary_touch, secondary_touch)
		var total_w: float = cell * 2.0 + gap
		var total_h: float = cell * 2.0 + gap
		var origin := (zone.get_center() - Vector2(total_w, total_h) * 0.5).floor()
		result = {
			"mode": MODE_COMPACT,
			"X": _cell_rect(origin, cell, secondary_touch),
			"A": _cell_rect(origin + Vector2(cell + gap, 0), cell, primary_touch),
			"Y": _cell_rect(origin + Vector2(0, cell + gap), cell, secondary_touch),
			"B": _cell_rect(origin + Vector2(cell + gap, cell + gap), cell, primary_touch),
		}
	result["visual_sizes"] = {
		"A": primary_visual,
		"B": primary_visual,
		"X": secondary_visual,
		"Y": secondary_visual,
	}
	result["bounds"] = _bounds_for(result)
	return result


static func _touch_rect(center: Vector2, side: float) -> Rect2:
	return Rect2((center - Vector2(side, side) * 0.5).floor(), Vector2(side, side))


static func _cell_rect(origin: Vector2, cell: float, side: float) -> Rect2:
	return Rect2((origin + Vector2(cell - side, cell - side) * 0.5).floor(), Vector2(side, side))


static func _bounds_for(layout: Dictionary) -> Rect2:
	var bounds := Rect2()
	var first := true
	for key in ["X", "Y", "A", "B"]:
		var rect: Rect2 = layout[key]
		if first:
			bounds = rect
			first = false
		else:
			bounds = bounds.merge(rect)
	return bounds
