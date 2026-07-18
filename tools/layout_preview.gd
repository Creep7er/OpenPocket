extends Control

const MainScene := preload("res://app/main.tscn")

var app: Control


func _ready() -> void:
	var options := _options()
	var profile := String(options.get("profile", "vgirl"))
	var from_profile := String(options.get("from-profile", profile))
	var route := String(options.get("route", "home"))
	var window_size := _parse_size(String(options.get("size", "852x393")))
	var debug := String(options.get("debug", "false")) == "true"
	var output := String(options.get("output", "artifacts/ui-preview/layout-preview.png"))
	PocketStorage.set_setting("console_profile", from_profile)
	DisplayServer.window_set_size(window_size)
	app = MainScene.instantiate()
	add_child(app)
	await _frames(5)
	if from_profile != profile:
		PocketStorage.set_setting("console_profile", profile)
		app.console_frame.call("_layout_for_window", Vector2(window_size), Rect2(Vector2.ZERO, Vector2(window_size)))
		await _frames(3)
	app.shell_view.booting = false
	match route:
		"library": app.shell_view.show_library(PocketPackages.get_packages())
		"store": app.shell_view.show_store()
		"settings": app.shell_view.show_settings()
		_: app.shell_view.show_home()
	app.console_frame.set_debug_overlay_enabled(debug)
	await _frames(3)
	var absolute := ProjectSettings.globalize_path("res://" + output.trim_prefix("res://"))
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var error := get_viewport().get_texture().get_image().save_png(absolute)
	print("Layout preview: ", output, " (", error, ")")
	get_tree().quit(0 if error == OK else 1)


func _options() -> Dictionary:
	var result: Dictionary = {}
	for argument in OS.get_cmdline_user_args():
		if not argument.begins_with("--") or "=" not in argument:
			continue
		var parts := argument.trim_prefix("--").split("=", true, 1)
		result[parts[0]] = parts[1]
	return result


func _parse_size(value: String) -> Vector2i:
	var parts := value.to_lower().split("x", false, 1)
	if parts.size() != 2:
		return Vector2i(852, 393)
	return Vector2i(maxi(320, int(parts[0])), maxi(240, int(parts[1])))


func _frames(count: int) -> void:
	for _index in range(count):
		await get_tree().process_frame
