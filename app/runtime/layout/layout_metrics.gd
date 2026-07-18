extends RefCounted
class_name LayoutMetrics

const SAFE_TOP_FALLBACK := 4.0
const SAFE_BOTTOM_FALLBACK := 8.0


static func safe_rect(window_size: Vector2) -> Rect2:
	var result := Rect2(Vector2.ZERO, window_size.floor())
	var display_safe := DisplayServer.get_display_safe_area()
	if display_safe.size.x > 0 and display_safe.size.y > 0 and display_safe.size.x <= window_size.x * 1.1:
		result = Rect2(display_safe.position, display_safe.size)
	if OS.has_feature("android"):
		result = result.grow_individual(0, -SAFE_TOP_FALLBACK, 0, -SAFE_BOTTOM_FALLBACK)
	return result
