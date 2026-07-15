extends Control
class_name PixelDpad

signal state_changed(button: String, pressed: bool)

var _active := ""


func _ready() -> void:
	custom_minimum_size = Vector2(176, 176)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_update_press(event.position, event.pressed)
		accept_event()
	if event is InputEventScreenTouch:
		_update_press(event.position, event.pressed)
		accept_event()
	if event is InputEventMouseMotion and _active != "":
		_update_press(event.position, true)
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_release()


func _draw() -> void:
	var p := PocketTheme.palette()
	var unit := int(floor(min(size.x, size.y) / 3.25))
	var center := Vector2i(int(size.x * 0.5), int(size.y * 0.5))
	var start := center - Vector2i(unit * 3 / 2, unit * 3 / 2)
	var parts: Dictionary = _parts(start, unit)
	var shadow_offset := Vector2(4, 4) if _active == "" else Vector2(2, 2)
	for key in parts.keys():
		draw_rect(Rect2(parts[key].position + shadow_offset, parts[key].size), p["dark"], true)
	for key in parts.keys():
		var fill: Color = p["light"] if key == _active else p["case_mid"]
		if key == "CENTER":
			fill = p["case_light"]
		draw_rect(parts[key], fill, true)
	var outline := Rect2(start, Vector2(unit * 3, unit * 3))
	draw_rect(Rect2(outline.position + Vector2(unit, 0), Vector2(unit, unit * 3)), p["dark"], false, 3)
	draw_rect(Rect2(outline.position + Vector2(0, unit), Vector2(unit * 3, unit)), p["dark"], false, 3)
	draw_rect(Rect2(Vector2(center) - Vector2(unit * 0.34, unit * 0.34), Vector2(unit * 0.68, unit * 0.68)), p["dark"], false, 3)
	draw_rect(Rect2(Vector2(center) - Vector2(unit * 0.18, unit * 0.18), Vector2(unit * 0.36, unit * 0.36)), p["case_light"], true)
	_draw_direction_marks(parts, p)


func _update_press(position: Vector2, pressed: bool) -> void:
	if not pressed:
		_release()
		return
	var next := _direction_for_position(position)
	if next == _active:
		return
	_release()
	_active = next
	if _active != "":
		state_changed.emit(_active, true)
	queue_redraw()


func _release() -> void:
	if _active == "":
		return
	state_changed.emit(_active, false)
	_active = ""
	queue_redraw()


func _direction_for_position(position: Vector2) -> String:
	var center := size * 0.5
	var delta := position - center
	if abs(delta.x) < size.x * 0.16 and abs(delta.y) < size.y * 0.16:
		return ""
	if abs(delta.x) > abs(delta.y):
		return PocketInput.RIGHT if delta.x > 0 else PocketInput.LEFT
	return PocketInput.DOWN if delta.y > 0 else PocketInput.UP


func _parts(start: Vector2i, unit: int) -> Dictionary:
	return {
		PocketInput.UP: Rect2(start + Vector2i(unit, 0), Vector2(unit, unit)),
		PocketInput.LEFT: Rect2(start + Vector2i(0, unit), Vector2(unit, unit)),
		"CENTER": Rect2(start + Vector2i(unit, unit), Vector2(unit, unit)),
		PocketInput.RIGHT: Rect2(start + Vector2i(unit * 2, unit), Vector2(unit, unit)),
		PocketInput.DOWN: Rect2(start + Vector2i(unit, unit * 2), Vector2(unit, unit)),
	}


func _draw_direction_marks(parts: Dictionary, p: Dictionary) -> void:
	var up: Rect2 = parts[PocketInput.UP]
	var down: Rect2 = parts[PocketInput.DOWN]
	var left: Rect2 = parts[PocketInput.LEFT]
	var right: Rect2 = parts[PocketInput.RIGHT]
	draw_rect(Rect2(up.position + Vector2(up.size.x * 0.38, 10), Vector2(up.size.x * 0.24, 12)), p["dark"], true)
	draw_rect(Rect2(down.position + Vector2(down.size.x * 0.38, down.size.y - 22), Vector2(down.size.x * 0.24, 12)), p["dark"], true)
	draw_rect(Rect2(left.position + Vector2(10, left.size.y * 0.38), Vector2(12, left.size.y * 0.24)), p["dark"], true)
	draw_rect(Rect2(right.position + Vector2(right.size.x - 22, right.size.y * 0.38), Vector2(12, right.size.y * 0.24)), p["dark"], true)
