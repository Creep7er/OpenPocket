extends Control

const PixelTouchButtonScene := preload("res://app/ui/components/pixel_touch_button.gd")
const PixelDpadScene := preload("res://app/ui/components/pixel_dpad.gd")

const SCREEN_ASPECT := 1.25
const MIN_SIDE_MARGIN := 8.0
const SAFE_FALLBACK_MARGIN := 10.0
const MAX_CONSOLE_WIDTH := 720.0
const MIN_TOUCH_TARGET := 56.0
const HEADER_RATIO := 0.055
const SCREEN_WIDTH_RATIO := 0.92
const SCREEN_MAX_HEIGHT_RATIO := 0.46
const SCREEN_GAP_RATIO := 0.038
const SYSTEM_BUTTON_RATIO := 0.052
const BOTTOM_MARGIN_RATIO := 0.045
const ACTION_TOUCH_PAD := 16.0

signal virtual_button_changed(button: String, pressed: bool)

var screen_holder: PanelContainer
var screen_container: SubViewportContainer
var screen_viewport: SubViewport
var dpad: PixelDpad
var action_buttons: Dictionary = {}
var system_buttons: Dictionary = {}
var debug_overlay_enabled := false
var current_screen: Node
var current_overlay: Control
var _content_rect := Rect2()
var _console_rect := Rect2()
var _screen_rect := Rect2()
var _safe_rect := Rect2()
var _controls_rect := Rect2()
var _action_cluster_rect := Rect2()
var _dpad_rect := Rect2()
var _menu_rect := Rect2()
var _back_rect := Rect2()
var _screen_scale := 1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_layout()
	resized.connect(_layout_controls)
	call_deferred("_layout_controls")
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func set_debug_overlay_enabled(value: bool) -> void:
	debug_overlay_enabled = value
	queue_redraw()


func set_screen(screen: Node) -> void:
	clear_screen_overlay()
	if current_screen != null and current_screen.get_parent() == screen_viewport:
		screen_viewport.remove_child(current_screen)
	current_screen = screen
	if screen.get_parent() != null:
		screen.get_parent().remove_child(screen)
	screen_viewport.add_child(screen)
	if screen is Control:
		var control := screen as Control
		control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func show_screen_overlay(overlay: Control) -> void:
	clear_screen_overlay()
	current_overlay = overlay
	screen_viewport.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func clear_screen_overlay() -> void:
	if current_overlay == null:
		return
	if current_overlay.get_parent() == screen_viewport:
		screen_viewport.remove_child(current_overlay)
	current_overlay.queue_free()
	current_overlay = null


func _build_layout() -> void:
	screen_holder = PanelContainer.new()
	screen_holder.add_theme_stylebox_override("panel", PocketTheme.pixel_style(PocketTheme.color("dark"), PocketTheme.color("case_light"), 4, 10))
	add_child(screen_holder)

	screen_container = SubViewportContainer.new()
	screen_container.stretch = true
	screen_container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen_holder.add_child(screen_container)

	screen_viewport = SubViewport.new()
	screen_viewport.size = PocketTheme.VIRTUAL_SCREEN_SIZE
	screen_viewport.disable_3d = true
	screen_viewport.transparent_bg = false
	screen_viewport.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	screen_container.add_child(screen_viewport)

	dpad = PixelDpadScene.new()
	dpad.state_changed.connect(func(button: String, pressed: bool) -> void: virtual_button_changed.emit(button, pressed))
	add_child(dpad)

	action_buttons = {
		PocketInput.A: _make_button("A", PocketInput.A, false, true),
		PocketInput.B: _make_button("B", PocketInput.B, false, true),
		PocketInput.X: _make_button("X", PocketInput.X),
		PocketInput.Y: _make_button("Y", PocketInput.Y),
	}
	for button in action_buttons.values():
		add_child(button)

	system_buttons = {
		PocketInput.MENU: _make_button("MENU", PocketInput.MENU, true),
		PocketInput.EXIT: _make_button("BACK", PocketInput.EXIT, true),
	}
	for button in system_buttons.values():
		add_child(button)


func _make_button(label: String, button: String, compact: bool = false, primary: bool = false) -> PixelTouchButton:
	var control := PixelTouchButtonScene.new()
	control.setup(label, button, compact, primary)
	control.state_changed.connect(func(pocket_button: String, pressed: bool) -> void: virtual_button_changed.emit(pocket_button, pressed))
	return control


func _layout_controls() -> void:
	var window_size: Vector2 = get_viewport_rect().size.floor()
	_safe_rect = _get_safe_rect(window_size)
	var outer_margin: float = clamp(_safe_rect.size.x * 0.018, 4.0, SAFE_FALLBACK_MARGIN)
	_content_rect = _safe_rect.grow(-outer_margin)
	var console_w: float = min(MAX_CONSOLE_WIDTH, _content_rect.size.x - MIN_SIDE_MARGIN * 2.0)
	if console_w < 320.0:
		console_w = _content_rect.size.x
	var width_t: float = clamp((console_w - 360.0) / 360.0, 0.0, 1.0)
	var max_console_ratio: float = lerpf(1.85, 1.55, width_t)
	var console_h: float = min(_content_rect.size.y, maxf(640.0, console_w * max_console_ratio))
	var console_x: float = floor(_content_rect.position.x + (_content_rect.size.x - console_w) * 0.5)
	var console_y: float = floor(_content_rect.position.y + (_content_rect.size.y - console_h) * 0.5)
	_console_rect = Rect2(Vector2(console_x, console_y), Vector2(floor(console_w), floor(console_h)))

	var header_h: float = floor(clamp(_console_rect.size.y * HEADER_RATIO, 36.0, 56.0))
	var screen_margin: float = floor(clamp(_console_rect.size.x * (1.0 - SCREEN_WIDTH_RATIO) * 0.5, 10.0, 22.0))
	var desired_screen_w: float = floor(_console_rect.size.x - screen_margin * 2.0)
	var desired_screen_h: float = floor(min(desired_screen_w / SCREEN_ASPECT, _console_rect.size.y * SCREEN_MAX_HEIGHT_RATIO))
	var screen_w: float = floor(desired_screen_h * SCREEN_ASPECT)
	var screen_x: float = floor(_console_rect.position.x + (_console_rect.size.x - screen_w) * 0.5)
	var screen_y: float = floor(_console_rect.position.y + header_h + clamp(_console_rect.size.y * 0.01, 6.0, 12.0))
	_screen_rect = Rect2(Vector2(screen_x, screen_y), Vector2(screen_w, desired_screen_h))
	screen_holder.position = _screen_rect.position
	screen_holder.size = _screen_rect.size
	screen_container.position = Vector2.ZERO
	screen_container.size = _screen_rect.size
	_screen_scale = floor(min(_screen_rect.size.x / float(PocketTheme.VIRTUAL_SCREEN_SIZE.x), _screen_rect.size.y / float(PocketTheme.VIRTUAL_SCREEN_SIZE.y)))
	if _screen_scale < 1.0:
		_screen_scale = min(_screen_rect.size.x / float(PocketTheme.VIRTUAL_SCREEN_SIZE.x), _screen_rect.size.y / float(PocketTheme.VIRTUAL_SCREEN_SIZE.y))

	var adaptive_gap: float = floor(clamp(_console_rect.size.y * SCREEN_GAP_RATIO, 20.0, 36.0))
	var system_h: float = floor(clamp(_console_rect.size.y * SYSTEM_BUTTON_RATIO, 40.0, 52.0))
	var bottom_margin: float = floor(clamp(_console_rect.size.y * BOTTOM_MARGIN_RATIO, 24.0, 44.0))
	var system_y: float = floor(_console_rect.end.y - bottom_margin - system_h)
	var controls_top: float = floor(_screen_rect.end.y + adaptive_gap)
	var controls_bottom: float = floor(system_y - clamp(_console_rect.size.y * 0.024, 14.0, 24.0))
	_controls_rect = Rect2(Vector2(_console_rect.position.x, controls_top), Vector2(_console_rect.size.x, maxf(MIN_TOUCH_TARGET * 2.6, controls_bottom - controls_top)))

	var side_pad: float = floor(clamp(_console_rect.size.x * 0.028, 10.0, 22.0))
	var center_gap: float = floor(clamp(_console_rect.size.x * 0.035, 12.0, 26.0))
	var dpad_size: float = floor(clamp(_console_rect.size.x * 0.52, 168.0, min(250.0, _controls_rect.size.y * 0.9)))
	var primary_size: float = floor(clamp(dpad_size * 0.42, 72.0, 96.0))
	var secondary_size: float = floor(primary_size * 0.86)
	var button_spacing: float = floor(primary_size * 0.82)
	var primary_touch_size: float = floor(maxf(MIN_TOUCH_TARGET, primary_size + ACTION_TOUCH_PAD))
	var action_bounds_size: Vector2 = Vector2(button_spacing * 2.0 + primary_touch_size, button_spacing * 2.0 + primary_touch_size)
	var total_controls_w: float = dpad_size + center_gap + action_bounds_size.x
	if total_controls_w > _console_rect.size.x - side_pad * 2.0:
		var shrink: float = (_console_rect.size.x - side_pad * 2.0) / total_controls_w
		dpad_size = floor(dpad_size * shrink)
		primary_size = floor(primary_size * shrink)
		secondary_size = floor(secondary_size * shrink)
		button_spacing = floor(button_spacing * shrink)
		primary_touch_size = floor(maxf(MIN_TOUCH_TARGET, primary_size + ACTION_TOUCH_PAD))
		action_bounds_size = Vector2(button_spacing * 2.0 + primary_touch_size, button_spacing * 2.0 + primary_touch_size)
		total_controls_w = dpad_size + center_gap + action_bounds_size.x

	var controls_x: float = floor(_console_rect.position.x + (_console_rect.size.x - total_controls_w) * 0.5)
	var controls_y: float = floor(_controls_rect.position.y + minf((_controls_rect.size.y - maxf(dpad_size, action_bounds_size.y)) * 0.48, 64.0))
	_dpad_rect = Rect2(Vector2(controls_x, controls_y + maxf(0.0, (action_bounds_size.y - dpad_size) * 0.5)), Vector2(dpad_size, dpad_size))
	dpad.position = _dpad_rect.position
	dpad.size = _dpad_rect.size

	var cluster_center: Vector2 = Vector2(
		floor(controls_x + dpad_size + center_gap + action_bounds_size.x * 0.5),
		floor(controls_y + maxf(dpad_size, action_bounds_size.y) * 0.5)
	)
	_place_action_center(PocketInput.X, cluster_center + Vector2(0, -button_spacing), secondary_size)
	_place_action_center(PocketInput.Y, cluster_center + Vector2(-button_spacing, 0), secondary_size)
	_place_action_center(PocketInput.A, cluster_center + Vector2(button_spacing, 0), primary_size)
	_place_action_center(PocketInput.B, cluster_center + Vector2(0, button_spacing), primary_size)
	_action_cluster_rect = Rect2(cluster_center - action_bounds_size * 0.5, action_bounds_size)

	var sys_w: float = floor(clamp(_console_rect.size.x * 0.19, 82.0, 112.0))
	var sys_gap: float = floor(clamp(_console_rect.size.x * 0.075, 28.0, 48.0))
	var sys_total: float = sys_w * 2.0 + sys_gap
	var sys_x: float = floor(_console_rect.position.x + (_console_rect.size.x - sys_total) * 0.5)
	_menu_rect = Rect2(Vector2(sys_x, system_y), Vector2(sys_w, system_h))
	_back_rect = Rect2(Vector2(sys_x + sys_w + sys_gap, system_y), Vector2(sys_w, system_h))
	system_buttons[PocketInput.MENU].position = _menu_rect.position
	system_buttons[PocketInput.MENU].size = _menu_rect.size
	system_buttons[PocketInput.EXIT].position = _back_rect.position
	system_buttons[PocketInput.EXIT].size = _back_rect.size
	queue_redraw()


func _place_action_center(button: String, center: Vector2, visual_size: float) -> void:
	var control: Control = action_buttons[button]
	var touch_size: float = floor(maxf(MIN_TOUCH_TARGET, visual_size + ACTION_TOUCH_PAD))
	control.position = (center - Vector2(touch_size, touch_size) * 0.5).floor()
	control.size = Vector2(touch_size, touch_size)


func _get_safe_rect(window_size: Vector2) -> Rect2:
	var rect: Rect2 = Rect2(Vector2.ZERO, window_size)
	var display_safe: Rect2i = DisplayServer.get_display_safe_area()
	if display_safe.size.x > 0 and display_safe.size.y > 0 and display_safe.size.x <= window_size.x * 1.1:
		rect = Rect2(display_safe.position, display_safe.size)
	if OS.has_feature("android"):
		rect = rect.grow_individual(0, -4, 0, -8)
	return rect


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	_draw_background_dither(p)
	_draw_case(p)
	if bool(PocketStorage.get_setting("debug_info", false)) or debug_overlay_enabled:
		_draw_debug_overlay(p)


func _draw_background_dither(p: Dictionary) -> void:
	for y in range(0, int(size.y), 10):
		for x in range((y / 10) % 2 * 10, int(size.x), 20):
			draw_rect(Rect2(Vector2(x, y), Vector2(10, 10)), p["mid"], true)


func _draw_case(p: Dictionary) -> void:
	if _console_rect.size == Vector2.ZERO:
		return
	draw_rect(_console_rect, p["case_dark"], true)
	draw_rect(_console_rect, p["case_light"], false, 3)
	draw_rect(Rect2(_console_rect.position + Vector2(6, 6), _console_rect.size - Vector2(12, 12)), p["case_mid"], false, 1)

	var header_y: float = _console_rect.position.y + 14.0
	PixelFont.draw_text(self, Vector2(_console_rect.position.x + 24, header_y), "OPENPOCKET", p["hi"], 3)
	PixelFont.draw_text(self, Vector2(_console_rect.end.x - 130, header_y + 7), "REV 02", p["case_light"], 1)
	draw_rect(Rect2(Vector2(_console_rect.end.x - 54, header_y + 4), Vector2(12, 12)), p["hi"], true)
	PixelFont.draw_text(self, Vector2(_console_rect.end.x - 36, header_y + 4), "PWR", p["case_light"], 1)


func _draw_screw(pos: Vector2, p: Dictionary) -> void:
	draw_rect(Rect2(pos, Vector2(10, 10)), p["case_mid"], true)
	draw_rect(Rect2(pos + Vector2(2, 4), Vector2(6, 2)), p["dark"], true)


func _draw_debug_overlay(p: Dictionary) -> void:
	var text := "WINDOW " + str(int(size.x)) + "X" + str(int(size.y))
	text += "\nSAFE " + str(int(_safe_rect.position.x)) + "," + str(int(_safe_rect.position.y)) + " " + str(int(_safe_rect.size.x)) + "X" + str(int(_safe_rect.size.y))
	text += "\nCONTENT " + str(int(_content_rect.size.x)) + "X" + str(int(_content_rect.size.y))
	text += "\nSCREEN " + _rect_text(_screen_rect)
	text += "\nDPAD " + _rect_text(_dpad_rect)
	text += "\nACTIONS " + _rect_text(_action_cluster_rect)
	text += "\nSCREEN SCALE " + str(_screen_scale)
	text += "\nASPECT " + str(snappedf(size.x / maxf(size.y, 1.0), 0.001))
	var box := Rect2(Vector2(12, 72), Vector2(238, 104))
	draw_rect(box, p["dark"], true)
	draw_rect(box, p["hi"], false, 2)
	PixelFont.draw_text(self, box.position + Vector2(6, 6), text, p["hi"], 1)


func _rect_text(rect: Rect2) -> String:
	return str(int(rect.position.x)) + "," + str(int(rect.position.y)) + " " + str(int(rect.size.x)) + "X" + str(int(rect.size.y))
