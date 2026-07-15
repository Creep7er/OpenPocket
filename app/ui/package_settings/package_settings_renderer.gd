extends RefCounted
class_name PackageSettingsRenderer


static func draw_row(canvas: CanvasItem, rect: Rect2, label: String, value: String, selected: bool, palette: Dictionary) -> void:
	if selected:
		canvas.draw_rect(rect, palette["light"], true)
		canvas.draw_rect(rect, palette["hi"], false, 2)
	var color: Color = palette["dark"] if selected else palette["hi"]
	var prefix := ">" if selected else " "
	PixelFont.draw_text(canvas, rect.position + Vector2(8, 5), prefix + " " + label, color, 1)
	if not value.is_empty():
		var text_size := PixelFont.measure(value, 1)
		PixelFont.draw_text(canvas, Vector2(rect.end.x - text_size.x - 8, rect.position.y + 5), value, color, 1)
