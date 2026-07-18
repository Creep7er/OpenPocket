extends Control

const MainScene := preload("res://app/main.tscn")
const SIZES: Array[Vector2i] = [
	Vector2i(640, 360), Vector2i(720, 360), Vector2i(800, 360),
	Vector2i(800, 480), Vector2i(852, 393), Vector2i(915, 412),
	Vector2i(960, 540), Vector2i(1280, 720), Vector2i(2400, 1080),
]


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	PocketStorage.set_setting("console_profile", "vgirl")
	PocketStorage.set_setting("direction_control", "dpad")
	var app := MainScene.instantiate()
	add_child(app)
	await get_tree().process_frame
	await get_tree().process_frame
	var lines: Array[String] = ["RESOLUTION | FONT SCALE | SCREEN RECT | DPAD RECT | ACTION RECT | SCREEN FILL | OVERLAP | RESULT"]
	var failed := false
	for window_size in SIZES:
		DisplayServer.window_set_size(window_size)
		app.size = Vector2(window_size)
		app.console_frame.size = Vector2(window_size)
		app.console_frame.call("_layout_for_window", Vector2(window_size), Rect2(Vector2.ZERO, Vector2(window_size)))
		await get_tree().process_frame
		var screen: Rect2 = app.console_frame.get("_screen_rect")
		var dpad: Rect2 = app.console_frame.get("_dpad_rect")
		var actions: Rect2 = app.console_frame.get("_action_cluster_rect")
		var menu: Rect2 = app.console_frame.get("_menu_rect")
		var back: Rect2 = app.console_frame.get("_back_rect")
		var console: Rect2 = app.console_frame.get("_console_rect")
		var reasons: Array[String] = []
		if screen.intersects(dpad): reasons.append("screen/dpad")
		if screen.intersects(actions): reasons.append("screen/actions")
		if dpad.intersects(actions): reasons.append("dpad/actions")
		if menu.intersects(back): reasons.append("menu/back")
		var overlap := not reasons.is_empty()
		var action_keys: Array = app.console_frame.action_buttons.keys()
		for first_index in range(action_keys.size()):
			for second_index in range(first_index + 1, action_keys.size()):
				var first: Control = app.console_frame.action_buttons[action_keys[first_index]]
				var second: Control = app.console_frame.action_buttons[action_keys[second_index]]
				if Rect2(first.position, first.size).intersects(Rect2(second.position, second.size)):
					overlap = true
					reasons.append(String(action_keys[first_index]) + "/" + String(action_keys[second_index]))
		var readable := screen.size.x >= 280.0 and screen.size.y >= 224.0
		var controls_ok := dpad.size.x >= 96.0
		var screen_fill: float = screen.size.x / console.size.x
		var fills_console := screen_fill >= 0.45
		var passed := not overlap and readable and controls_ok and fills_console
		failed = failed or not passed
		lines.append("%dx%d | %d | %s | %s | %s | %d%% | %s | %s" % [window_size.x, window_size.y, int(app.console_frame.get("_ui_text_scale")), _rect(screen), _rect(dpad), _rect(actions), int(screen_fill * 100.0), "YES" if overlap else "NO", "PASS" if passed else "FAIL"])
		if not reasons.is_empty(): lines.append("  overlap: " + ", ".join(reasons))
	var output := ProjectSettings.globalize_path("res://artifacts/ui-preview/vgirl-layout-report.txt")
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file != null:
		file.store_string("\n".join(lines) + "\n")
	for line in lines:
		print(line)
	app.free()
	get_tree().quit(1 if failed else 0)


func _rect(rect: Rect2) -> String:
	return "%d,%d %dx%d" % [int(rect.position.x), int(rect.position.y), int(rect.size.x), int(rect.size.y)]
