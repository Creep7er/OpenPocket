extends Control
class_name PixelTouchButton

const DEBUG_DRAW_BOUNDS := false
const ACTION_TOUCH_PAD := 8.0
const COMPACT_TOUCH_PAD := 6.0

signal state_changed(button: String, pressed: bool)

var label := "A"
var button := ""
var compact := false
var primary := false
var _pressed := false


func setup(text: String, pocket_button: String, is_compact: bool = false, is_primary: bool = false) -> void:
	label = text
	button = pocket_button
	compact = is_compact
	primary = is_primary
	custom_minimum_size = Vector2(94, 44) if compact else Vector2(86, 86)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_set_pressed(event.pressed)
		accept_event()
	if event is InputEventScreenTouch:
		_set_pressed(event.pressed)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_pressed(false)


func _draw() -> void:
	var p := PocketTheme.palette()
	var offset := Vector2(0, 2) if _pressed else Vector2.ZERO
	var rect := _visual_rect().grow(-1)
	rect.position += offset
	if compact:
		_draw_compact_button(rect, p)
	else:
		_draw_stepped_button(rect, p)
	var text_scale: int = 2
	var text_size: Vector2i = PixelFont.measure(label, text_scale)
	PixelFont.draw_text(self, (rect.position + (rect.size - Vector2(text_size)) * 0.5).floor(), label, p["hi"], text_scale)
	if DEBUG_DRAW_BOUNDS:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 0, 0), false, 1)


func _set_pressed(value: bool) -> void:
	if _pressed == value:
		return
	_pressed = value
	state_changed.emit(button, _pressed)
	queue_redraw()


func _draw_compact_button(rect: Rect2, p: Dictionary) -> void:
	if not _pressed:
		draw_rect(Rect2(rect.position + Vector2(4, 4), rect.size), p["dark"], true)
	draw_rect(rect, p["case_mid"], true)
	draw_rect(rect, p["dark"], false, 2)
	draw_rect(Rect2(rect.position + Vector2(5, 5), rect.size - Vector2(10, 10)), p["case_light"], false, 2)


func _draw_stepped_button(rect: Rect2, p: Dictionary) -> void:
	var inset: float = floor(min(rect.size.x, rect.size.y) * 0.18)
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(rect.position.x + inset, rect.position.y),
		Vector2(rect.position.x + rect.size.x - inset, rect.position.y),
		Vector2(rect.position.x + rect.size.x, rect.position.y + inset),
		Vector2(rect.position.x + rect.size.x, rect.position.y + rect.size.y - inset),
		Vector2(rect.position.x + rect.size.x - inset, rect.position.y + rect.size.y),
		Vector2(rect.position.x + inset, rect.position.y + rect.size.y),
		Vector2(rect.position.x, rect.position.y + rect.size.y - inset),
		Vector2(rect.position.x, rect.position.y + inset),
	])
	if not _pressed:
		var shadow: PackedVector2Array = PackedVector2Array()
		for point in points:
			shadow.append(point + Vector2(4, 4))
		draw_colored_polygon(shadow, p["dark"])
	draw_colored_polygon(points, p["case_mid"] if primary else p["case_light"])
	draw_polyline(points + PackedVector2Array([points[0]]), p["dark"], 3.0)
	var inner: Rect2 = rect.grow(-7)
	draw_rect(inner, p["case_light"] if primary else p["case_mid"], false, 2)


func _visual_rect() -> Rect2:
	if compact:
		var visual_size: Vector2 = Vector2(maxf(1.0, size.x - COMPACT_TOUCH_PAD * 2.0), maxf(1.0, size.y - COMPACT_TOUCH_PAD * 2.0))
		return Rect2(((size - visual_size) * 0.5).floor(), visual_size.floor())
	var side: float = floor(maxf(1.0, minf(size.x, size.y) - ACTION_TOUCH_PAD * 2.0))
	var visual_size: Vector2 = Vector2(side, side)
	return Rect2(((size - visual_size) * 0.5).floor(), visual_size)
