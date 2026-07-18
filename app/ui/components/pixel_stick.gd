extends Control
class_name PixelStick

signal state_changed(button: String, pressed: bool)

var floating := false
var deadzone := 0.28
var _touch_index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _active_directions: Array[String] = []


func _ready() -> void:
	custom_minimum_size = Vector2(176, 176)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_reset_visual_origin()


func configure(is_floating: bool, new_deadzone: float) -> void:
	floating = is_floating
	deadzone = clampf(new_deadzone, 0.1, 0.75)
	_release_all()
	_reset_visual_origin()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index < 0:
			_touch_index = event.index
			_origin = event.position if floating else size * 0.5
			_update_stick(event.position)
			accept_event()
		elif not event.pressed and event.index == _touch_index:
			_release_all()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update_stick(event.position)
		accept_event()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_touch_index = -2
			_origin = event.position if floating else size * 0.5
			_update_stick(event.position)
		else:
			_release_all()
		accept_event()
	elif event is InputEventMouseMotion and _touch_index == -2:
		_update_stick(event.position)
		accept_event()


func _update_stick(position: Vector2) -> void:
	var radius: float = maxf(1.0, minf(size.x, size.y) * 0.32)
	var delta := position - _origin
	if delta.length() > radius:
		delta = delta.normalized() * radius
	_knob = _origin + delta
	var normalized := delta / radius
	var next: Array[String] = []
	if normalized.x <= -deadzone: next.append(PocketInput.LEFT)
	if normalized.x >= deadzone: next.append(PocketInput.RIGHT)
	if normalized.y <= -deadzone: next.append(PocketInput.UP)
	if normalized.y >= deadzone: next.append(PocketInput.DOWN)
	_apply_directions(next)
	queue_redraw()


func _apply_directions(next: Array[String]) -> void:
	for direction in _active_directions:
		if not next.has(direction): state_changed.emit(direction, false)
	for direction in next:
		if not _active_directions.has(direction): state_changed.emit(direction, true)
	_active_directions = next


func _release_all() -> void:
	for direction in _active_directions:
		state_changed.emit(direction, false)
	_active_directions.clear()
	_touch_index = -1
	_reset_visual_origin()
	queue_redraw()


func _reset_visual_origin() -> void:
	_origin = size * 0.5
	_knob = _origin


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _touch_index < 0:
		_reset_visual_origin()
	if what == NOTIFICATION_EXIT_TREE:
		_release_all()


func _draw() -> void:
	var p := PocketTheme.palette()
	var radius: float = floor(minf(size.x, size.y) * 0.32)
	var base := Rect2(_origin - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
	_draw_stepped_disc(base, p["case_mid"], p["dark"])
	var knob_radius: float = floor(radius * 0.46)
	var knob := Rect2(_knob - Vector2(knob_radius, knob_radius), Vector2(knob_radius * 2.0, knob_radius * 2.0))
	_draw_stepped_disc(knob, p["light"], p["dark"])
	draw_rect(Rect2(_origin - Vector2(3, 3), Vector2(6, 6)), p["hi"], true)


func _draw_stepped_disc(rect: Rect2, fill: Color, outline: Color) -> void:
	var step: float = floor(minf(rect.size.x, rect.size.y) * 0.2)
	var points := PackedVector2Array([
		Vector2(rect.position.x + step, rect.position.y), Vector2(rect.end.x - step, rect.position.y),
		Vector2(rect.end.x, rect.position.y + step), Vector2(rect.end.x, rect.end.y - step),
		Vector2(rect.end.x - step, rect.end.y), Vector2(rect.position.x + step, rect.end.y),
		Vector2(rect.position.x, rect.end.y - step), Vector2(rect.position.x, rect.position.y + step),
	])
	draw_colored_polygon(points, fill)
	draw_polyline(points + PackedVector2Array([points[0]]), outline, 3.0)

