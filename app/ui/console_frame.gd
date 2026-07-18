extends Control

const PixelTouchButtonScene := preload("res://app/ui/components/pixel_touch_button.gd")
const PixelDpadScene := preload("res://app/ui/components/pixel_dpad.gd")
const PixelStickScene := preload("res://app/ui/components/pixel_stick.gd")
const ActionCluster := preload("res://app/runtime/layout/action_cluster_layout.gd")

const SCREEN_ASPECT := 1.25
const MIN_SIDE_MARGIN := 8.0
const SAFE_FALLBACK_MARGIN := 10.0
const MAX_CONSOLE_WIDTH := 720.0
const MAX_VGIRL_HEIGHT := 1080.0
const MIN_TOUCH_TARGET := 56.0
const HEADER_RATIO := 0.055
const SCREEN_WIDTH_RATIO := 0.92
const SCREEN_MAX_HEIGHT_RATIO := 0.46
const SCREEN_GAP_RATIO := 0.038
const SYSTEM_BUTTON_RATIO := 0.052
const BOTTOM_MARGIN_RATIO := 0.045
const ACTION_TOUCH_PAD := 16.0
const VGIRL_SIDE_GAP := 8.0
const VGIRL_MIN_SIDE_ZONE := 124.0
const VGIRL_SCALE_STEP := 0.125
const VGIRL_MAX_DPAD_SIZE := 260.0

signal virtual_button_changed(button: String, pressed: bool)

var screen_holder: PanelContainer
var screen_container: SubViewportContainer
var screen_viewport: SubViewport
var dpad: PixelDpad
var stick: PixelStick
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
var _shell_scale := 1.0
var _ui_text_scale := 1
var _layout_signature := ""


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_build_layout()
	resized.connect(_layout_controls)
	call_deferred("_layout_controls")
	queue_redraw()


func _process(_delta: float) -> void:
	var signature := String(PocketStorage.get_setting("console_profile", "vboy")) + ":" + String(PocketStorage.get_setting("direction_control", "dpad")) + ":" + String(PocketStorage.get_setting("stick_mode", "fixed")) + ":" + String(PocketStorage.get_setting("stick_side", "left"))
	if signature != _layout_signature:
		_layout_signature = signature
		_layout_controls()
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
	_apply_screen_ui_scale()


func show_screen_overlay(overlay: Control) -> void:
	clear_screen_overlay()
	current_overlay = overlay
	screen_viewport.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_screen_ui_scale()


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
	PocketScreen.bind_viewport(screen_viewport)

	dpad = PixelDpadScene.new()
	dpad.state_changed.connect(func(button: String, pressed: bool) -> void: virtual_button_changed.emit(button, pressed))
	add_child(dpad)
	stick = PixelStickScene.new()
	stick.state_changed.connect(func(button: String, pressed: bool) -> void: virtual_button_changed.emit(button, pressed))
	add_child(stick)

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
	_layout_for_window(window_size)


func _layout_for_window(window_size: Vector2, safe_override: Rect2 = Rect2()) -> void:
	_safe_rect = safe_override if safe_override.size != Vector2.ZERO else _get_safe_rect(window_size)
	var use_stick := String(PocketStorage.get_setting("direction_control", "dpad")) == "stick"
	dpad.visible = not use_stick
	stick.visible = use_stick
	stick.configure(String(PocketStorage.get_setting("stick_mode", "fixed")) == "floating", float(PocketStorage.get_setting("stick_deadzone", 0.28)))
	if String(PocketStorage.get_setting("console_profile", "vboy")) == "vgirl" and window_size.x > window_size.y:
		_layout_vgirl()
		return
	_ui_text_scale = 1
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
	_place_stick(_dpad_rect)

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
	_apply_screen_ui_scale()
	queue_redraw()


func _layout_vgirl() -> void:
	var outer_margin: float = clamp(_safe_rect.size.y * 0.018, 4.0, SAFE_FALLBACK_MARGIN)
	_content_rect = _safe_rect.grow(-outer_margin)
	var console_h: float = minf(MAX_VGIRL_HEIGHT, _content_rect.size.y)
	var console_w: float = minf(_content_rect.size.x, console_h * 1.78)
	_console_rect = Rect2((_content_rect.position + (_content_rect.size - Vector2(console_w, console_h)) * 0.5).floor(), Vector2(console_w, console_h).floor())
	var margin: float = floor(clamp(_console_rect.size.y * 0.026, 8.0, 20.0))
	var header_h: float = floor(clamp(_console_rect.size.y * 0.075, 28.0, 52.0))
	var available_h: float = _console_rect.size.y - header_h - margin * 2.0
	var system_h: float = floor(clamp(available_h * 0.12, 36.0, 48.0))
	var system_gap: float = floor(clamp(available_h * 0.025, 6.0, 14.0))
	var display_h: float = available_h - system_h - system_gap
	var max_screen_w: float = maxf(240.0, _console_rect.size.x - (VGIRL_MIN_SIDE_ZONE + VGIRL_SIDE_GAP) * 2.0 - margin * 2.0)
	if _console_rect.size.y >= 500.0:
		max_screen_w = minf(max_screen_w, floor(_console_rect.size.x * 0.50))
	var candidate_scale: float = minf(display_h / float(PocketScreen.LOGICAL_SIZE.y), max_screen_w / float(PocketScreen.LOGICAL_SIZE.x))
	# Eighth-step nearest scaling keeps the screen large on 16:9 devices without
	# applying fractional scaling to the physical controls.
	var display_scale: float = candidate_scale
	if candidate_scale >= 1.0:
		display_scale = maxf(1.0, floor(candidate_scale / VGIRL_SCALE_STEP) * VGIRL_SCALE_STEP)
	var screen_w: float = floor(float(PocketScreen.LOGICAL_SIZE.x) * display_scale)
	var screen_h: float = floor(float(PocketScreen.LOGICAL_SIZE.y) * display_scale)
	var center_w: float = screen_w
	var screen_x: float = floor(_console_rect.get_center().x - screen_w * 0.5)
	var display_top: float = _console_rect.position.y + header_h + margin
	_screen_rect = Rect2(Vector2(screen_x, display_top + (display_h - screen_h) * 0.5).floor(), Vector2(screen_w, screen_h))
	screen_holder.position = _screen_rect.position
	screen_holder.size = _screen_rect.size
	screen_container.position = Vector2.ZERO
	screen_container.size = _screen_rect.size
	_screen_scale = minf(screen_w / float(PocketScreen.LOGICAL_SIZE.x), screen_h / float(PocketScreen.LOGICAL_SIZE.y))
	_shell_scale = _console_rect.size.y / 360.0
	_ui_text_scale = 2

	var left_zone := Rect2(
		Vector2(_console_rect.position.x + margin, display_top),
		Vector2(_screen_rect.position.x - _console_rect.position.x - margin - VGIRL_SIDE_GAP, display_h)
	)
	var right_zone := Rect2(
		Vector2(_screen_rect.end.x + VGIRL_SIDE_GAP, display_top),
		Vector2(_console_rect.end.x - margin - _screen_rect.end.x - VGIRL_SIDE_GAP, display_h)
	)
	_controls_rect = Rect2(left_zone.position, Vector2(right_zone.end.x - left_zone.position.x, display_h))
	var roomy_controls := _console_rect.size.y >= 500.0
	var control_limit: float = VGIRL_MAX_DPAD_SIZE if roomy_controls else 156.0
	var zone_ratio: float = 0.88 if roomy_controls else 0.82
	var height_ratio: float = 0.72 if roomy_controls else 0.62
	var control_size: float = floor(clamp(minf(left_zone.size.x * zone_ratio, display_h * height_ratio), 96.0, control_limit))
	_dpad_rect = Rect2((left_zone.get_center() - Vector2(control_size, control_size) * 0.5).floor(), Vector2(control_size, control_size))
	dpad.position = _dpad_rect.position
	dpad.size = _dpad_rect.size
	_place_stick(_dpad_rect)

	var primary_size: float = floor(clamp(control_size * (0.48 if roomy_controls else 0.44), 68.0 if roomy_controls else 52.0, 104.0 if roomy_controls else 86.0))
	var secondary_size: float = floor(clamp(primary_size * 0.84, 60.0 if roomy_controls else 44.0, 88.0 if roomy_controls else 72.0))
	_place_action_cluster(right_zone, primary_size, secondary_size)

	var sys_w: float = floor(clamp(center_w * 0.25, 70.0, 94.0))
	var sys_gap: float = floor(clamp(center_w * 0.08, 18.0, 30.0))
	var sys_x: float = floor(_console_rect.get_center().x - (sys_w * 2.0 + sys_gap) * 0.5)
	var sys_y: float = floor(display_top + display_h + system_gap)
	_menu_rect = Rect2(Vector2(sys_x, sys_y), Vector2(sys_w, system_h))
	_back_rect = Rect2(Vector2(sys_x + sys_w + sys_gap, sys_y), Vector2(sys_w, system_h))
	system_buttons[PocketInput.MENU].position = _menu_rect.position
	system_buttons[PocketInput.MENU].size = _menu_rect.size
	system_buttons[PocketInput.EXIT].position = _back_rect.position
	system_buttons[PocketInput.EXIT].size = _back_rect.size
	_apply_screen_ui_scale()
	queue_redraw()


func _apply_screen_ui_scale() -> void:
	for target in [current_screen, current_overlay]:
		if target != null and target.has_method("set_ui_scale"):
			target.call("set_ui_scale", _ui_text_scale)


func _place_stick(direction_rect: Rect2) -> void:
	var scale_factor: float = clampf(float(PocketStorage.get_setting("stick_size", 1.0)), 0.8, 1.3)
	var stick_size: Vector2 = (direction_rect.size * scale_factor).floor()
	stick.position = (direction_rect.get_center() - stick_size * 0.5).floor()
	stick.size = stick_size


func _place_action_center(button: String, center: Vector2, visual_size: float) -> void:
	var control: Control = action_buttons[button]
	control.set_meta("uniform_style", false)
	control.set_meta("visual_size", visual_size)
	control.custom_minimum_size = Vector2(MIN_TOUCH_TARGET, MIN_TOUCH_TARGET)
	var touch_size: float = floor(maxf(MIN_TOUCH_TARGET, visual_size + ACTION_TOUCH_PAD))
	control.position = (center - Vector2(touch_size, touch_size) * 0.5).floor()
	control.size = Vector2(touch_size, touch_size)


func _place_action_cluster(zone: Rect2, primary_size: float, secondary_size: float) -> void:
	var layout: Dictionary = ActionCluster.calculate(zone, primary_size, secondary_size, MIN_TOUCH_TARGET, ACTION_TOUCH_PAD)
	var visual_sizes: Dictionary = Dictionary(layout["visual_sizes"])
	for button in [PocketInput.X, PocketInput.Y, PocketInput.A, PocketInput.B]:
		var control: Control = action_buttons[button]
		var rect: Rect2 = layout[button]
		control.set_meta("uniform_style", true)
		control.custom_minimum_size = rect.size
		control.position = rect.position
		control.size = rect.size
		control.set_meta("visual_size", float(visual_sizes[button]))
	_action_cluster_rect = layout["bounds"]


func _get_safe_rect(window_size: Vector2) -> Rect2:
	return LayoutMetrics.safe_rect(window_size)


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
	PixelFont.draw_text(self, Vector2(_console_rect.position.x + 24, header_y), BrandConfig.PRODUCT_NAME.to_upper(), p["hi"], 2)
	PixelFont.draw_text(self, Vector2(_console_rect.end.x - 130, header_y + 7), "REBORN", p["case_light"], 1)
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
	text += "\nSHELL SCALE " + str(snappedf(_shell_scale, 0.01))
	text += "\nTEXT SCALE " + str(_ui_text_scale)
	text += "\nASPECT " + str(snappedf(size.x / maxf(size.y, 1.0), 0.001))
	var box := Rect2(Vector2(12, 72), Vector2(238, 132))
	draw_rect(box, p["dark"], true)
	draw_rect(box, p["hi"], false, 2)
	PixelFont.draw_text(self, box.position + Vector2(6, 6), text, p["hi"], 1)


func _rect_text(rect: Rect2) -> String:
	return str(int(rect.position.x)) + "," + str(int(rect.position.y)) + " " + str(int(rect.size.x)) + "X" + str(int(rect.size.y))
