extends RefCounted
class_name ActionClusterLayout

const MODE_PLUS := "plus"


static func calculate(zone: Rect2, primary_visual: float, secondary_visual: float, minimum_touch: float, touch_pad: float) -> Dictionary:
	var gap := 4.0
	var available_side: float = maxf(1.0, minf(zone.size.x, zone.size.y))
	var maximum_touch: float = floor((available_side - gap * 2.0) / 3.0)
	var requested_visual: float = maxf(primary_visual, secondary_visual)
	var requested_touch: float = maxf(minimum_touch, requested_visual + touch_pad)
	var touch_size: float = maxf(40.0, minf(requested_touch, maximum_touch))
	var visual_size: float = floor(minf(requested_visual, maxf(32.0, touch_size - 6.0)))
	var spacing: float = touch_size + gap
	var center := zone.get_center().floor()
	var result: Dictionary = {
		"mode": MODE_PLUS,
		"X": _touch_rect(center + Vector2(0, -spacing), touch_size),
		"Y": _touch_rect(center + Vector2(-spacing, 0), touch_size),
		"A": _touch_rect(center + Vector2(spacing, 0), touch_size),
		"B": _touch_rect(center + Vector2(0, spacing), touch_size),
	}
	result["visual_sizes"] = {
		"A": visual_size,
		"B": visual_size,
		"X": visual_size,
		"Y": visual_size,
	}
	result["bounds"] = _bounds_for(result)
	return result


static func _touch_rect(center: Vector2, side: float) -> Rect2:
	return Rect2((center - Vector2(side, side) * 0.5).floor(), Vector2(side, side))


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
